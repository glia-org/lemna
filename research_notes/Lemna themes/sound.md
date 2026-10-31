# Sound for a mindful theme: an ambient bed and a quieter click pack, as of 2026-10-31

Scope: the sound half of a "mindful" theme for Lemna (the user, 2026-10-30: "ambient sounds like wind chimes and light
rain drops" and "typing sounds that lean more into that theme"). Five questions: does the evidence behind K1's D1 ("no
ambient sound bed") hold for non-speech nature sound; how a bed is made in an app (loop, level, fades, Bluetooth, other
audio); where CC0 or CC BY recordings of light rain, wind chimes and a still pond are; which key sounds fit the theme,
with Return and the send (⌘⏎); how a theme binds pack, bed and send. Read first: `research_notes/Flow sounds and
ambience/sounds.md` (cited as *sounds.md*), DESIGN K1, `lib/LemnaClicks/THIRD_PARTY.md`, `ClickPlayer.swift`,
`Mixer.swift`, and `research_notes/Lemna themes/architecture.md` §4 (the bed's engine sketch; not repeated here).

Tags as in *sounds.md*: **[E]** controlled study; **[P]** practice, vendor text, review or forum; **[M]** my own
measurement (method in §6); **[I]** inference. **UNVERIFIED** marks what I could not check. Freesound pages were read
on 2026-10-31 without a login; licences are as each page showed them that day. Nothing was listened to.

The engine as it stands: `ClickPlayer` is one `AVAudioEngine` with one mono `AVAudioSourceNode` on its main mixer
(`ClickPlayer.swift` header and `init`), not a bare output unit; the output-only AUHAL is DESIGN Open 6's untested
fallback. The engine runs whenever the sound is on, the box shown or not; only Sound ▸ Off pauses it
(`enabled`).

## Takeaway

1. **Light rain: neutral, not harmful, and defensible as an opt-in bed.** The closest direct test played looped rain,
   birdsong or silence at 60 dB during a serial mental-arithmetic task (N = 18): rain did not differ from silence
   (t(17) = 1.14, p = .81, Bonferroni), birdsong was worse than rain (t(17) = 3.15, p = .017) [E]. A water sound laid over
   office speech removed most of the speech's harm to serial recall (errors vs speech d = .51) and left proofreading
   untouched [E]. Heavy rain beat silence on hard arithmetic (accuracy 70.6 % vs 62.2 %, N = 50) [E]. No study shows a
   nature bed *improves* writing. D1's g = −0.21 is for white/pink noise, not rain.
2. **Wind chimes: the riskiest sound to put under writing.** A chime is a sparse sequence of different pitches: the
   changing-state sound of the irrelevant-sound literature. Tone sequences add 4–7 percentage points of serial-recall
   errors (12–53 % relative); level does not reduce it; quiet does not make it safe [E]. Nobody has tested one strike
   every few seconds. The recordings measured here ring 0.9 s to over 4 s, carry 6–50 tonal peaks and strike 10–75 times a
   minute (metal), or clatter in bursts of up to 300 strikes a minute between long silences (bamboo) [M].
3. **A still pond at night** (a dense chorus of frogs, toads and crickets, no birds) behaves like rain: one recording
   measures as steady as Apple's rain [M]. Lapping water and bird-rich ponds are eventful (loudness range 8–20 LU) [M].
4. **Apple's own rain bed, measured:** 17 clips of 70–169 s (34.8 min), AAC 256 kbit/s stereo, 66.7 MB, mastered to
   −15 to −21 LUFS, loudness range 0.5–3 LU, under 1 % of its energy below 150 Hz [M]. Its Mac settings have one volume slider and no
   "when media is playing" option; that option is iPhone and iPad only [P]. That steadiness is the target to match.
5. **Level:** the Keychron clicks at volume 0.6 make −35.6 / −34.2 / −32.3 LUFS at 3 / 5 / 8 keys a second [M].
   Default bed level −46 LUFS: the click heads then stand 20–26 dB over it across the band [M].
   - Fade in over 1.5 s at the summon and out over 0.6 s from the close or the hand-off.
   - No duck under the send: the box closes at ⌘⏎, so the bed is already falling.
   - Stop the bed whenever the box is hidden.
6. **CC0 rain found that meets that profile:**
   - felix.blume 585845 (14 min, 48/24): light for its first 5½ minutes, then heavier.
   - felix.blume 512334 (10 min, 96/24): steady throughout.
   - jmbphilmes 200273 (95 s, mono).
   - tim.kahn 169031, CC BY 4.0, "loops well".
   60 s test loops with a 3 s equal-power crossfade show no level dip and no click at the seam [M].
7. **Mindful keys:** an unpitched, short wooden or stone tap, one pitch family, no melody. In practice, OmmWriter's
   xylophone keystroke was judged "absolutely NOT for fast typing" [P].
   - **Letters:** four CC0 takes of a stone on wood (worthahep88). They are 26–30 ms to −30 dB, 1.2–1.9 kHz and
     unpitched. At −6 dBFS peak they land at −31 to −33 LUFS M max, where the Keychron letter sits (−32.2) [M].
   - **Return:** a low wooden slit drum (VCSL, CC0).
   - **Send:** one soft hand chime, a single fixed note (VCSL, CC0). It must peak about 14 dB lower than −6 dBFS to sit
     at the Return's loudness [M].
8. **Engine, beyond architecture §4:**
   - a per-kind pitch-jitter field: ±3 % is a semitone of random pitch on a tonal tap, a changing-state sequence by
     construction;
   - sends levelled by loudness, not peak;
   - loop points picked by spectral match;
   - only the chosen bed in memory;
   - optionally, a check at the summon for another app playing audio. Core Audio's process list answered without a
     prompt here [M].

## 1. D1 re-examined for nature sound

### 1.1 What D1 rests on and what it does not cover

D1 (DESIGN K1, *sounds.md* §8.6) rests on four points:
- noise slightly harms people without ADHD;
- speech in a bed lowers writing fluency;
- macOS already has Background Sounds;
- "no notes or water drops: changing pitches disrupt verbal memory".

The g = −0.212 (with ADHD +0.249) comes from **white and pink noise**, almost all white, exposures
of minutes, six studies sharing one author ([Nigg et al. 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC11283987/)). It
says nothing direct about rain. The speech finding stands and keeps any bed with voices out. The pitch rule is
confirmed below and is what decides chimes.

The literature below was gathered by a second research agent (abstract or full text as marked; DOIs given). I read
Newbold 2017 and Proverbio 2018 myself.

### 1.2 Nature sound played during a task

| Study | Design | Result | Relevance |
|---|---|---|---|
| Newbold, Luton, Cox & Gould 2017, CHI EA ([PDF](https://discovery.ucl.ac.uk/id/eprint/1561792/)), read | Within subjects, N = 18, counterbalanced. Silence vs looped rain ("low acoustic variation") vs birdsong ("high"), 60 dB. 10 running-total addition problems each (after Perham), chosen as a serial working-memory task | F(2,34) = 5.57, p = .008, η² = .247. Silence vs rain t(17) = 1.144, p = .806; silence vs birdsong p = .143; birdsong vs rain t(17) = 3.154, p = .017. Mood and arousal n.s. | The one direct test of rain during a serial task: **rain ≈ silence, birdsong worse than rain**. A diary study in the same paper (N = 4, 40 min of reading and writing to self-mixed nature sound) reports use for calm and to block other people's noise [P] |
| Proverbio et al. 2018, PLOS ONE ([PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC5821317/)), read | N = 50 (25 introverts, 25 extroverts). 180 arithmetic problems under heavy rain with occasional thunder, silence, or music; clips matched at "89.0 dB" in MP3Gain (a file level, not SPL) | Difficult items: hits 70.61 % rain vs 62.2 % silence (p < .0001); background F(4,184) = 16.62, ηp² = .265. Easy items: no effect | Steady-ish rain ≥ silence on a hard non-verbal task; arousal account; one clip from YouTube |
| Haapakangas et al. 2011, Acta Acustica 97:641 ([doi](https://doi.org/10.3813/AAA.918444)), full text by the agent | N = 54. Speech at 44.8 dB masked by pink noise, ventilation, music or spring water at ≈ 45 dB; silence and speech alone | Serial-recall errors vs silence rose for speech d = .43, pink noise d = .32, ventilation d = .40, vocal music d = .55, **not for water**. Water vs speech d = .51 fewer errors. Proofreading: no effect, F(6,306) = 1.51, p = .17 | Water masks speech best; no water-alone condition |
| Hongisto et al. 2017, Front Psychol 8:1177 ([doi](https://doi.org/10.3389/fpsyg.2017.01177)) | Field study: an office of 77; 18 answered in all conditions. Four water maskers vs pseudo-random noise, 43–45 dB, 3 weeks each | Water rated worse: less acoustic satisfaction, more disturbance for 3 of 4 water sounds | The lab advantage did not hold over weeks of masking at work |
| Gould van Praag et al. 2017, Sci Rep 7:45273 ([doi](https://doi.org/10.1038/srep45273)) | fMRI, N = 17, low-load reaction-time task during 5½-minute soundscapes | RT 413 vs 423 ms, naturalistic vs artificial (p = .029) | During a task, not verbal |
| DeLoach, Carter & Braasch 2015 (ASA meeting abstract) | Mountain stream vs a conventional masker vs none, office | Claimed better productivity and mood; N, levels and statistics UNVERIFIED | Weak |

### 1.3 Nature sound in a break, and stress

These test sound heard *before* a task (Attention Restoration Theory), against urban sound, rarely against silence:

- **Van Hedger et al. 2019** ([doi](https://doi.org/10.3758/s13423-018-1539-1)), N = 63. Nature vs urban clips at about
  70 dB. Composite pre–post gain 0.82 vs 0.01 (B = 0.46, p = .003). How much people liked the sounds did not predict
  the gain.
- **Emfield & Neider 2014** ([doi](https://doi.org/10.3389/fpsyg.2014.00548)), 192 analysed: null (ηp² = .04).
- **Zhang, Kang & Kang 2017**, N = 70, abstract only: natural sounds beat traffic and machine sounds in a rest
  (p = .027).
- **Shu & Ma 2019** ([doi](https://doi.org/10.3390/ijerph16020293)), children at 50 dBA: stream and fountain sounds were
  best for reaction time.
- **Alvarsson, Wiens & Nilsson 2010** ([doi](https://doi.org/10.3390/ijerph7031036)), N ≈ 40. After a stressor, skin
  conductance recovered faster with nature sound at 50 dB than with traffic at 80 dB (F(3,105) = 2.73, p = .048). It
  was not faster than traffic at 50 dB or ambience at 40 dB, and there was no task during the sound.

Meta-analyses:
- **[Buxton et al. 2021](https://doi.org/10.1073/pnas.2013097118):** stress or annoyance g = −0.60; health or positive
  affect g = 1.63 (CI 0.09–3.16). Cognition is pooled into that health group, with no subset of its own.
- **Zhu et al. 2024** (Sci Total Environ 921:171052; abstract): "no consistent conclusions" on cognition.

[I] Nature sound calms and is liked; what it does to the work done while it plays is close to nothing either way when
it is steady.

### 1.4 Changing state, tones, capture

All of these are as read by the second agent.

**Ellermeier & Zimmer 2014**, a review in Acoust Sci Tech 35:10 ([doi](https://doi.org/10.1250/ast.35.10)):
- Stationary noise does not differ from quiet.
- Playback level does not change the size of the effect.
- Irrelevant tones add 4.0–7.0 percentage points of errors, 11.8–52.7 % relative. Jones & Macken 1993 Exp. 1 is
  +5.5 points (23.2 %).
- Speech adds 8.8–29.0 points; amplitude-modulated noise 1.2–2.7.
- Pitch change must be segmented to disrupt: continuous glides do not, glides broken by silence do.

**Schlittmeier et al. 2012**, Atten Percept Psychophys 74:194: predicted disruption ≈ fluctuation strength / 0.68 vacil
× 7.5 %. Continuous noise is 0.02–0.03 vacil (about +0.3 % errors), changing tones 0.53 (about +5.8 %), dense traffic
0.08–0.14.

**Rate:** more heard tokens mean more disruption for words (Bridges & Jones 1996). **No study tests tones at one every
1–3 s** (gap).

**Capture:** deviant or unexpected events capture attention on a separate route; capture fades when changes become
predictable (Hughes, Vachon & Jones 2007; Vachon et al. 2012; abstracts).

**Habituation:** mixed.
- Banbury & Berry 1997: about 20 min, partly undone by a 5-min break.
- Röer, Bell & Buchner 2014: much reduced after eight repetitions of the same distractor.
- Ellermeier & Zimmer: the effect "does not habituate".

**Preference does not protect:** liked music hurt serial recall more than disliked music (Perham & Sykora 2012, N = 25).
That matters because a user picks the bed.

### 1.5 Verdict per bed

| Bed | Acoustic kind | Evidence | Verdict |
|---|---|---|---|
| Light rain, dense, no thunder, traffic or gutter drips | Broadband, steady (Apple's rain: 3 s loudness SD 0.4–1.0 LU [M]) | Rain ≈ silence (Newbold; t(17) = 1.14). Water masks speech (d = .51). Rain ≥ silence on hard arithmetic. Noise in non-ADHD g −0.21 is the nearest risk | **Opt-in bed, defensible** |
| Night pond: insect and frog chorus, no birds | Repeated tokens, dense; near-steady [M] | No direct test; a repeated token is the steady-state case | Second bed, same conditions |
| Lapping water, shore | Periodic events, loudness range 8–20 LU [M] | Hongisto: water maskers rated worse over weeks | Not as a writing bed |
| Birdsong | Changing state | Worse than rain (t(17) = 3.15, p = .017) | No |
| Wind chimes (metal or bamboo) | Sparse, segmented, tonal; ring 2.4–4 s; or clattering bursts [M] | Tones add 4–7 points of errors, independent of level; sparse rates untested; capture by surprise | **Not under writing.** If built anyway: the alternative in the Recommendations, off by default, never timed to the writer's pauses |

A bed is defensible when all of these hold:
- it is opt-in and off by default, stopped with ⌘K like the clicks;
- it is steady (3 s loudness SD ≤ about 1 LU, no bursts, nothing under 150 Hz to speak of, no voices, birds, thunder or
  traffic);
- it has no audible period;
- it sits well under the clicks;
- it plays only while the box is up;
- the copy promises calm or masking, not focus or speed;
- [I] people with ADHD are the one group with an expected gain (Nigg, g +0.25).

## 2. Craft of a bed

### 2.1 The precedent: macOS Background Sounds

- [P] Settings on the Mac:
  - **Sound** (choose one) and **Volume**.
  - **Equalizer** and **Stop sounds with a timer**: the Beats guide lists both with no device restriction.
  - **Turn off background sounds when your Mac isn't in use:** sleep, the screen saver or the lock.
  - **"Use When Media is Playing (iPhone and iPad only)"**, which on those devices sets a separate volume while media
    plays ([Mac User Guide](https://support.apple.com/guide/mac-help/mchl3061cdc6/mac);
    [Beats guide](https://support.apple.com/en-nz/guide/beats/dev971a2c815/web)).
  - On the Mac the slider "adjusts the volume of background sounds in relation to the volume set for playing other
    media" ([AbilityNet](https://mcmw.abilitynet.org.uk/how-to-use-background-sounds-to-help-you-focus-in-macos-15-sequoia)).
  - It keeps playing beside other media until switched off
    ([MacMost](https://macmost.com/use-mac-background-sounds-to-cancel-noise-and-focus-on-your-work.html)).
- [M] Its asset catalogue on this Mac (`/System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets`, posted
  2022-10-04) lists six sounds as downloads:
  - noises 1.9–2.0 MB each;
  - Ocean 65.4 MB, Rain 66.7 MB, Stream 75.6 MB.
- [M] The Rain zip (SHA-1 `089e773a…db51`, as the catalogue gives) holds `Rain_1.m4a` … `Rain_17.m4a`:
  - format: AAC, 48 kHz stereo, 256 kbit/s; 69.6–169.3 s each, 2,087 s in all;
  - loudness: integrated −20.8 (Rain_1) rising to −15.0 LUFS (Rain_15); loudness range 0.5–3.0 LU; true peak up to
    +1.1 dBTP; in the seven clips measured (1, 3, 6, 9, 12, 15, 17), 3 s loudness SD 0.36–1.01 LU and no 400 ms
    window 6 LU over the median;
  - spectrum: 0.3–0.7 % of energy under 150 Hz, 3.5–10.9 % above 5 kHz; centroid 2.13 kHz (Rain_1) falling to
    1.32 kHz (Rain_15): the later clips are louder and darker;
  - seams: the last 3 s of clip n matches the first 3 s of clip n+1 within 0.5–0.9 dB (band-spectrum RMS), as well as
    or better than its own start (0.9–2.3 dB) [I: consistent with consecutive pieces of one recording played in
    sequence; how the player strings them is not documented].
- [I] What Apple ships is about 35 minutes of steady, dark-ish rain with no events and no short loop, at about 30× the
  size of Lemna today (the app is 2.4 MB).

### 2.2 Looping without a period

- [P] From *sounds.md* §8.2:
  - A Soft Murmur: 120 s main loops plus a 10 s "glue" clip across the seam.
  - myNoise: ten octave bands of two 15–24 s stems each, whole-mix period about 13 years.
  - platen: 40 s beds with an offline equal-power overhang and **no rare events**, which "would be recognised on every
    loop".
  - `AVAudioPlayerNode … .loops` is sample-exact; AAC decodes to its exact valid frames.
- [M] 60 s loops with a 3 s equal-power crossfade baked in offline, from four previews:
  - the crossfade region is within −0.34 to +0.22 dB of the rest of the loop: no dip;
  - the sample step at the wrap is 0.00015–0.0058 against a 99.9th percentile of 0.0027–0.061 for ordinary steps: no
    click;
  - band spectra 2 s before and after the wrap differ by 0.8–2.1 dB RMS (max 1.6–5.6 dB). The 5.6 dB case (585845) had
    a 2.3 dB step in 0.5 s loudness across the wrap. [I] Pick the loop points by search, keeping the pair whose 2 s
    band spectra match within about 1 dB, as Apple's consecutive clips do.
- [M] Size of a 60 s stereo loop: AAC 96 kbit/s 0.75 MB, 128 kbit/s 0.99 MB (`afconvert`); 16-bit PCM 11.5 MB. Decoded
  Float32 stereo: 23 MB a minute (*sounds.md* §8.4).
- [I] A 90 s loop of steady rain has no landmark to recognise if it holds no event. The test is the one platen applies:
  no 400 ms window more than a few LU over the median. Two layers of different lengths (say 89 s and 127 s, both cut
  from the same recording) push the period to hours, but a second layer of rain adds density and level; one loop is
  enough for rain. For chimes, never loop: strikes are one-shots at random times (architecture §4).

### 2.3 Level against the clicks

- [M] A synthetic 60 s typing stream:
  - make-up: Keychron letters with every sixth key a space, no repeat, 70 ms minimum gap, volume 0.6;
  - integrated loudness: −35.6, −34.2 and −32.3 LUFS at 3, 5 and 8 keys a second; peaks −10.1 dBFS;
  - the Soft pack at 5 keys a second: −33.0 LUFS;
  - single cuts at −6 dBFS: the Keychron letter-1 −32.2 and the Return −28.3 LUFS M max (as THIRD_PARTY.md).
- [M] A rain bed at −46 LUFS (about 12 LU under the 5 keys/s stream), mixed under it. The loudest 10 % of 10 ms typing
  frames stand above the bed by:

  | Band | Margin, median |
  |---|---|
  | Broadband | 20.2–25.7 dB |
  | 1–4 kHz | 20.3–23.2 dB |
  | 200–1000 Hz | 3.3–19.0 dB |

  The beds were 169031, 200273, 669487 and the pond 673259. The rain's centroid (1.6–2.5 kHz) sits on the clicks'
  (1.9–2.8 kHz), so a brighter rain masks the clicks more than a dark one.
- [I] Proposal:
  - **−46 LUFS default**, every bed normalised to its target offline, so a bed switch changes no level.
  - If a level control is ever wanted, three steps: −52, −46, −40.
  - The bed's gain is separate from the click volume (0.6); the system volume scales both alike.
  - The masking guidance cited by Hongisto 2017 for offices is ≤ 45 dB(A) at the ear; Lemna cannot know the SPL.

### 2.4 Fades, the send, hidden box

- [P] Lemna's timings (DESIGN F1/P1):
  - the box opens in 300 ms from 87 % with a fade;
  - it closes in a 200 ms fade, the dim with it;
  - the hand-off runs 260 ms;
  - the send's arrival lands inside those 260 ms.
- [I] Proposal:
  - **Fade-in:** 1.5 s on an equal-power (sine) curve from the show. A broadband sound that rises in 300 ms reads as
    something switched on.
  - **Fade-out:** 0.6 s from the close, or from ⌘⏎'s key-down; the engine keeps rendering after the window is gone
    (architecture §4: "the audio may outlast the dim").
  - **A summon during the fade-out** ramps up from the current gain, so Esc and re-summon leave no gap.
  - **No duck under the send.** The send already starts the fade-out, and at −6 dBFS peaks its M max of −28 to
    −25 LUFS (THIRD_PARTY.md) sits far over a −46 LUFS bed.
  - **Hidden box:** the bed stops. It is a writing bed; Background Sounds covers a desk bed, and Rain's ambience already
    ends at the close (A1).
  - **⌘K:** silences clicks and bed alike (architecture §4).
  - **Reduce Motion:** does not apply to sound.

### 2.5 CPU, memory, battery

- [I] Rendering a stereo bed is a read, a gain ramp and a wrap: two multiply-adds per sample per channel. *sounds.md*
  §8.4 measured procedural noise at 0.009–0.017 % of a core, and a buffer read costs the same order.
- [P] The cost that matters is the audio device staying awake. Lemna's engine already runs whenever the sound is on,
  box or no box (`enabled`), so a bed adds no new wake-up; it only makes the stream non-silent.
- [P] `AudioHardwarePowerHint` "Favor Saving Power" trades latency for power (CoreAudio `AudioHardware.h`). It would
  undo K1's 128-frame IO buffer: not for Lemna.
- [M/I] Memory: only the chosen bed, decoded at the choice off the main thread:
  - a 90 s stereo loop is 34.6 MB as Float32, 17.3 MB as 16-bit;
  - three beds preloaded as Float32 would be about 100 MB, so K1's "every pack loaded at launch" should not extend to
    beds.
- Power at rest, bed on vs off: not measured. The method is `sudo powermetrics --samplers cpu_power -i 1000` with the box
  open.

### 2.6 Bluetooth and AirPods

- [P] Latency does not matter for a bed: nothing has to line up with a key.
- [P] Thock's AirPods glitches came from stopping and restarting the stream; keeping it warm fixed them (*sounds.md*
  §7), and Lemna keeps it warm.
- [P] AirPods switch to a device when audio starts there
  ([Apple](https://support.apple.com/104988)). One user reports an app switching them by opening an audio stream, with
  nothing playing ([Anki forum](https://forums.ankiweb.net/t/opening-anki-on-macos-switches-airpods-from-iphone-to-mac-without-audio-playback/71252)).
  [I] Lemna's running engine may do that already; a bed that starts at every summon makes it likelier. UNVERIFIED (no
  AirPods here, DESIGN Open 6). Test before shipping.

### 2.7 When the Mac already plays audio

- [P] Apple's Mac Background Sounds has no media rule. Thock mutes its clicks by polling `osascript` for four players
  every 3 s (*sounds.md* §7). Nothing on macOS ducks other apps.
- [M] Core Audio's process objects can be read without a prompt. On this Mac (macOS 26, SDK 26.1) a 30-line probe read
  `kAudioHardwarePropertyProcessObjectList` (status 0, 21 client processes) and `kAudioProcessPropertyIsRunningOutput`
  on each (1 running output), with no permission dialog. Per the header, `IsRunningOutput` = 1 means "the process is
  running IO and there is at least one active output stream". First macOS version with these: UNVERIFIED (they came
  with the Core Audio taps of macOS 14; Lemna targets 14).
- [I] Running IO is not the same as playing music: a paused browser tab can keep a stream open. Two rules are possible:
  - **(a)** none: the bed plays at its level and the user turns it off. This is Apple's Mac behaviour.
  - **(b)** at each summon, if another process runs output, start the bed 6 dB lower, or not at all. This is iOS's
    "Use When Media is Playing".

  Recommend (a) first, (b) only if the user asks.

## 3. Sources for the beds

Freesound pages: `https://freesound.org/s/<id>/` (redirects to `/people/<user>/sounds/<id>/`). HQ previews:
`https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader id>-hq.ogg` (Ogg Vorbis, about 192 kbit/s stereo).
Originals download only with a login. "Measured" = my measurement of the HQ preview: the first 3 MB (90–420 s) unless
marked full. The columns are explained in §6. All licences below were read on each page on 2026-10-31.

### 3.1 Light rain

| ID | Author (uploader id) | Licence | Length, original | Content (page) | Measured | Notes |
|---|---|---|---|---|---|---|
| [585845](https://freesound.org/people/felix.blume/sounds/585845/) | felix.blume (1661766) | CC0 | 14:02, WAV 48/24 stereo | Night rain in a forest by a village, Brazil, from a balcony; ORTF Schoeps CCM4, MixPre-6 | **Full:** first 5½ min −26.1 to −25.4 LUFS a minute (short-term median), then the rain grows by about 10 LU; bursts only at 8:52–9:10 and 11:46–12:34; first 96 s: S-SD 0.36 LU, LF 0.2 %, centroid 2.03 kHz | **First pick.** Cut 60–120 s from 0:30–5:30 |
| [512334](https://freesound.org/people/felix.blume/sounds/512334/) | felix.blume (1661766) | CC0 | 10:00, WAV 96/24 stereo | Light rain in a field of banana trees, Veracruz; AB B&K 4006, SD 833 | **Full:** −26.6 to −29.5 LUFS a minute, S-SD 1.34 LU over 10 min, 12 short bursts (0:12–3:04, 6:41); steadiest 90 s from 7:33 (0.58 LU); centroid 1.90 kHz | Second pick, broad leaves |
| [169031](https://freesound.org/people/tim.kahn/sounds/169031/) | tim.kahn (7037) | **CC BY 4.0** | 9:46, WAV 48/24 stereo | "A quiet rainfall on leaves in the middle of a quiet forest. Loops well"; AT4021 pair, rain hitting the mics edited out | S-SD 0.62 LU, burst 0.1 %, LF 1.4 %, centroid 2.49 kHz | Credit line needed |
| [200273](https://freesound.org/people/jmbphilmes/sounds/200273/) | jmbphilmes (2322692) | CC0 | 1:35, WAV 48/24 **mono** | "Rain dropping light. Rural land, without any surrounding sounds"; ME66, Tascam HD-P2 | I −52.5 LUFS (a quiet take: +6 dB to −46), S-SD 0.35 LU, burst 0, LF 0.7 %, centroid 1.76 kHz | Steadiest of all; mono, so narrow |
| [669487](https://freesound.org/people/xkeril/sounds/669487/) | xkeril (13504080) | CC0 | 0:54, WAV 48/24 stereo | "Moderate/heavy rain hitting and dripping on roofs tiles", from a window; H5 + SGH-6 | S-SD 0.51 LU, burst 0, LF 4.9 %, centroid 1.60 kHz | Heavier than "light"; short |
| [536843](https://freesound.org/people/Garuda1982/sounds/536843/) | Garuda1982 (2061858) | CC0 | 10:03, WAV 44.1/16 stereo | Rain in a forest, Leipzig; Sony PCM-D100 | S-SD 0.45 LU, burst 0, LF 11.0 %, centroid 2.40 kHz | Some low rumble: high-pass ≈ 120 Hz |
| [573335](https://freesound.org/people/visionear/sounds/573335/) | visionear (10869493) | CC0 | 1:32, WAV 48/24 stereo | "Soft Rain Ambience" | S-SD 1.15 LU, LF 15.2 %, centroid 1.90 kHz | Low rumble |
| [869851](https://freesound.org/people/SignatureSoundsOrg/sounds/869851/) | SignatureSoundsOrg (19205925) | CC0 | 1:03, WAV 44.1/16 stereo | Rain on a window, close; uploaded 2026-09-10 by a new account with a promotional site | S-SD 0.66 LU, centroid 0.72 kHz (dark); 18 onsets a minute (taps on glass) | Provenance thin |
| [81819](https://freesound.org/people/silencyo/sounds/81819/) | silencyo (280284) | CC0 | 0:49, AIFF 48/16 stereo | Rain on a window in a reverberant room; "a nice false rain pouring during a shooting" (a rain machine), drips outside | S-SD 0.62 LU, LF 2.6 %, centroid 1.18 kHz | Film rain; short |
| [658879](https://freesound.org/people/xkeril/sounds/658879/) | xkeril (13504080) | CC0 | 2:25, WAV 48/24 stereo | Courtyard rain, "some metallic gutter dripping left" | S-SD 0.62 LU, centroid 1.93 kHz | The gutter drip is a pitched repeating event |

Measured and rejected:
- 466241 (richwise, CC0): traffic, an aeroplane, gusts; LF 50 %, LRA 7.6.
- 757276 (Garuda1982, CC0): suburban; LF 77 %, bursts 17 %.
- 100495 (CC BY 3.0) and 678435 (CC0): LF 90–91 %, wind or handling.
- 194848 (CC0): 55 % above 5 kHz, LRA 10.5.
- 640655 (CC0): 43 % above 5 kHz at −55.6 LUFS, likely hiss.
- 725603 (CC0): "re-mastered … noise reduction", LF 50 %.
- 833924 (CC0): drops on a roof window, 62 onsets a minute.
- 554419 (CC0): a blackbird and a motor.
- 575378 (CC0): a siren and a train horn.
- 852917 (CC0): city, LF 37 %.
- 607070 (CC0): MP3 at source.
- 422052 (CC0): an Instagram-tag request; LF 13 %.

Earlier candidates in *sounds.md* §8.3 not re-measured: 527499 is heavy rain on a plastic roof, not light.

### 3.2 Wind chimes

| ID | Author (uploader id) | Licence | Length, original | Content (page) | Measured | Notes |
|---|---|---|---|---|---|---|
| [432813](https://freesound.org/people/Chris%20W/sounds/432813/) | Chris W (2059546) | CC0 | 3:01, WAV 48/24 stereo | "Metal windchimes in a light breeze", outdoors, Northumberland | 47 onsets a minute, 37 % of 10 ms frames 30 dB down (gaps), ring 2.4 s to −30 dB, 27 tonal peaks 0.7–4.6 kHz | **Most natural**; strikes to cut for one-shots |
| [378431](https://freesound.org/people/Kinoton/sounds/378431/) | Kinoton (2247456) | CC0 | 1:17, WAV 48/24 stereo | Koshi chime, "eight metal tones surrounded by a bamboo resonance tube. a1-d2-f2-g2-a2-d3-f3-a3", ORTF Rode M5 | 36 onsets a minute, ring ≥ 4 s, peaks 225–7409 Hz, centroid 0.73 kHz | A meditation chime with a fixed set of notes. The page adds "By using this sound you agree to a license agreement. Read more about it in the terms of use" (most likely Freesound's own terms; read before use) |
| [437337](https://freesound.org/people/giddster/sounds/437337/) | giddster (1738686) | CC0 | 1:29, WAV 44.1/32 stereo | Chimes "over a longer period", indoors, Zoom H1 | 26 onsets a minute, gaps 16 %, ring ≥ 4 s, 15 tonal peaks 1.0–7.9 kHz | Most downloaded CC0 chime (17,857); dense |
| [586253](https://freesound.org/people/easy_thunder/sounds/586253/) | easy_thunder (4965426) | CC0 | 6:05, FLAC 48/16 stereo | "7 sets of wind chimes, one of bamboo & 6 metal", played by hand in a studio "to simulate a brisk summer breeze" | A continuous wash: gaps 4 %, S-SD 4.7 LU, 50 tonal peaks | A shimmer, not strikes |
| [196712](https://freesound.org/people/Littleboot/sounds/196712/) | Littleboot (652446) | CC0 | 3:56, WAV 44.1/24 stereo | "Five rakes of a large wind chime", studio | Glissandi; LRA 25 LU | Rakes are musical gestures: no |
| [336664](https://freesound.org/people/MrCisum/sounds/336664/), [266951](https://freesound.org/people/janbezouska/sounds/266951/) | MrCisum (1954708); janbezouska (3287894) | CC0 | 1:51 48/24; 1:23 48/24 | Small metal chimes, close | Centroid 6.2 and 7.6 kHz; 67 % and 93 % above 5 kHz | Too bright |
| [556153](https://freesound.org/people/NatBon/sounds/556153/) | NatBon (12344524) | CC0 | 1:33, WAV 44.1/16 stereo | Zaphir chimes, "Blue Moon", at home | LF 41 % (rumble), 63 onsets a minute | Rumble |
| [412416](https://freesound.org/people/Alex_hears_things/sounds/412416/) | Alex_hears_things (2309965) | CC0 | 0:33, WAV 96/24 stereo | "Some bamboo wind chimes in the breeze" | 38 onsets a minute, LF 37 % (wind on the mic), 4 weak tonal peaks | Bamboo; short |
| [739142](https://freesound.org/people/GoatsheadCastle/sounds/739142/) | GoatsheadCastle (14605753) | CC0 | 0:33, WAV 44.1/16 stereo | Bamboo chime in a garden, light wind, birds, a wood pigeon, no post | Clatter: bursts up to 282 strikes a minute, 78 % gaps, strikes 60 ms to −30 dB | Birds |
| [67046](https://freesound.org/people/gmni/sounds/67046/) | gmni (261599) | CC0 | 0:50, WAV 44.1/16 stereo | Bamboo wind chimes | Bursts up to 140 strikes a minute, 79 % gaps, 150 ms to −30 dB | The most-downloaded CC0 bamboo chime (5,988) |
| [17090](https://freesound.org/people/jppi_Stu/sounds/17090/), [401040](https://freesound.org/people/InspectorJ/sounds/401040/) | jppi_Stu (56518); InspectorJ (5121236) | **CC BY 4.0** | 1:05 48/16; 0:56 44.1/24 | Bamboo chimes (internal mic of a media player; a gift shop, noise removed) | Clatter 130–305 a minute, 270–320 ms rings | Credit needed |
| [323047](https://freesound.org/people/be-steele/sounds/323047/) | be-steele (589889) | CC0 | 2:35, WAV 44.1/24 stereo | "Struck metal tones, bell tones, and wind chime samples … time stretched, reversed and slowed down" | A continuous tonal drone: 0.4 onsets a minute, S-SD 2.4 LU, centroid 0.29 kHz, 75 tonal peaks | Not chimes as heard, but unsegmented: continuous pitch does not disrupt as segmented pitch does (§1.4) |

[M] In short:
- **Metal chimes:** long-ringing (0.9 s for a small chime close up; 2.4 s to over 4 s for the rest, 4 s being the
  measuring cap), strongly tonal, striking 10–75 times a minute.
- **Bamboo:** short (60–350 ms), weakly pitched (2–8 tonal peaks), and comes as clattering bursts between silences.
- [I] Both are changing state. Bamboo's bursts after silence are also the "unexpected event" of the capture account.

CC BY 4.0 chime ambiences not used: InspectorJ 353194, 353501 (a PaulStretch of 353194).

### 3.3 A still pond (third bed)

| ID | Author (uploader id) | Licence | Length, original | Content (page) | Measured | Notes |
|---|---|---|---|---|---|---|
| [673259](https://freesound.org/people/felix.blume/sounds/673259/) | felix.blume (1661766) | CC0 | 3:01, WAV 48/24 stereo | Pond at night: frog, toad and cricket at a village's edge, Venezuelan Amazon, **distant motor**; MS MKH50 + MKH30 | S-SD 0.72 LU, LRA 2.1, burst 0.3 %, LF 0.2 %, centroid 3.18 kHz | **Pick.** Check the motor by ear; brighter than rain, so set 2 dB lower |
| [481883](https://freesound.org/people/parret/sounds/481883/) | parret (8143650) | CC0 | 5:37, WAV 44.1/24 stereo | Two night ambiences combined, one "alongside of a pond"; crickets; low cuts at 3 kHz and 500 Hz, a stereo widener; made for a game | S-SD 0.34 LU, LRA 0.9, centroid 4.81 kHz | Steadiest; processed and thin |
| [32655](https://freesound.org/people/greysound/sounds/32655/) | greysound (189568) | CC0 | 1:21, WAV 48/24 stereo | Frogs and crickets by a ranch pond at 1 AM; "aggressively … EQ'd to remove a nearby gas generator" | S-SD 0.82 LU, I −14.0 LUFS, almost nothing above 5 kHz | EQ'd hard; short |
| [637945](https://freesound.org/people/kyles/sounds/637945/) | kyles (612689) | CC0 | 2:03, FLAC 48/24 stereo | "Water lake waves light gentle lap at boats on beach" | LRA 10.2, bursts 6.9 %, centroid 1.19 kHz | Calmest lapping; still eventful |
| [614299](https://freesound.org/people/TheFlyFishingFilmmaker/sounds/614299/), [573191](https://freesound.org/people/TRP/sounds/573191/), [568819](https://freesound.org/people/TRP/sounds/568819/), [352356](https://freesound.org/people/Alex_hears_things/sounds/352356/) | TheFlyFishingFilmmaker (6501596); TRP (97550); Alex_hears_things (2309965) | CC0 | 2:55 44.1/16; 1:34 96/24; 2:13 48/24; 2:45 48/16 | Small waves lapping on lakes and a shore | LRA 8.6–20.3, bursts 16–33 % | Periodic events: no |
| [759738](https://freesound.org/people/Garuda1982/sounds/759738/) | Garuda1982 (2061858) | CC0 | 6:51, WAV 48/24 stereo | Village pond, white wagtail | Bursts 16 %, 34 dB from floor to peaks | Birdsong: no |
| [260165](https://freesound.org/people/felix.blume/sounds/260165/) | felix.blume (1661766) | CC0 | 5:00, WAV 96/24 stereo | Frogs and toads in a castle moat at night, two hydrophones | LRA 10.3, bursts 21.5 % | Underwater: odd |

Rejected:
- 584045 (bullfrogs "like plucked, loose banjo strings": tonal events);
- 744098 (a joke upload);
- 361875 (an air conditioner);
- 135561, 387868 (frog choruses, not measured).

### 3.4 Not usable

These are as *sounds.md* §8.3 found them, re-read for the brief:
- **BBC Sound Effects:** RemArc licence, personal or educational use, or a paid licence.
- **Pixabay:** no "standalone" redistribution; an unedited loop in a bundle comes close to that.
- **Sonniss GDC:** not to be supplied "as files".
- **Freesound NC and ND sounds:** excluded by the filter used here.

## 4. Typing sounds for the theme

### 4.1 What exists in practice

- [P] **OmmWriter** (the mindful writing app):
  - four ambient and five instrumental tracks;
  - "Each letter you write creates a subtle, reassuring sound" ([description](https://ommwriter.com/description/));
  - keystroke options "like rain drops, typewriter keys, or bamboo chimes"
    ([Computers and Composition Online webtext](http://cconlinejournal.org/composing_text/webtext/sound.html));
  - seven keystroke sounds in the paid version (several review summaries; count UNVERIFIED);
  - per Capterra reviews: the volumes of music and keys cannot be set apart, only muted, and the music drowns the keys.
- [P] A reviewer's verdict on OmmWriter's seven sounds ([Young 2021](https://abigailyoung.com/posts/ommwriter-review)):

  | Sound | Reviewer's words |
  |---|---|
  | 01 | "a bubble typing on a mechanical keyboard" |
  | 02 | "so quiet, I can't really hear it over my own typing (without headphones)", "like a leaf hitting the ground" |
  | 03 | "a little drum machine left out in the rain" |
  | 04 | "the pattern isn't based on the key you press, but any keystroke advances the pattern" |
  | 05 | "a xylophone echo in a wet cave. Cute in a small dose but absolutely NOT for fast typing" ("a demented jack-in-the box" at speed) |
  | 06 | "fingers drumming on a cardboard box" |
  | 07 | "eraser end of a pencil clinking around a metal tin cup" |

- [I] What survives a fast typist is what K1 already found: short, dark-to-mid, low pitch salience.
  - Melodic or sequenced sounds (05, 04) fail.
  - Sounds below the real keyboard's own noise (02) vanish.
- [I] Good ideas for a mindful pack:
  - wood (a fingertip, a soft woodblock, a temple block);
  - stone (a pebble or a Go stone on wood);
  - felt (a muted tap);
  - paper (a pencil eraser on heavy paper).
- [I] Ruled out:
  - drops (pitch sweeps);
  - notes, chimes and bells per key (tonal sequences);
  - anything with more than one pitch across the letters.

### 4.2 The pitch rule, made concrete

- [M] Pitch salience is the share of the 120 ms after a hit within ±3 % of its strongest peak. The Keychron letters
  score 0.02–0.16: no pitch to hear. VCSL's woodblock scores 0.39–0.66 at 1,364–1,369 Hz across takes (13 cents
  apart): a clear, fixed note.
- [I] Lemna plays every sample at a random rate of ±3 % (DESIGN K1), about ±0.5 semitone. On an unpitched click that is
  colour. On a pitched tap it is a random sequence of notes within a semitone: the changing-state case the pack is
  meant to avoid.
- [I] So a tonal pack needs a pitch jitter of at most ±0.5 % (±9 cents) or none, and gets its variety from takes and
  level. The same holds for a pitched Return or send.
- [I] Space, Return and Backspace at different pitches make a two- or three-note pattern every few keys. The Keychron
  pack also differs by class, but with no pitch to hear. In a tonal pack, keep every class in one pitch family or
  unpitched.

### 4.3 Candidates (CC0 unless marked)

[M] figures are from the loudest hit:
- **Centroid** and **>5k**: the first 40 ms, after a Tukey window with 2 ms tapers. The same method gives the Keychron
  letters 1.9–2.8 kHz and 7–22 %, as THIRD_PARTY.md.
- **−30 dB:** the time from the peak to −30 dB.
- **M max:** the cut normalised to −6 dBFS as K1's packs (80 ms, or the span given).

| Idea | ID / file | Author (uploader id) | Original | What it is | Measured | Notes |
|---|---|---|---|---|---|---|
| **Stone on wood** | [319223](https://freesound.org/people/worthahep88/sounds/319223/), [319226](https://freesound.org/people/worthahep88/sounds/319226/), [319227](https://freesound.org/people/worthahep88/sounds/319227/), [319228](https://freesound.org/people/worthahep88/sounds/319228/) | worthahep88 (3443504) | WAV 48/16 stereo, 0.13–0.74 s each | "Rocks hitting wood" (made to imitate bullets on wood) | Centroid 1.2–1.9 kHz, 0–4 % >5k, −30 dB at 26–30 ms, salience 0.13–0.34 (unpitched), M max −31.0 to −33.1 | **Letters.** Four takes, matched to the Keychron letter (−32.2) as they stand |
| Go stones | [588317](https://freesound.org/people/billhails2/sounds/588317/) | billhails2 (12616419) | **Ogg at source**, 80 kbit/s mono, 7.1 s | "Five varied sounds of a Yunzi go stone" on two boards (a tabletop board and a thin shin-kaya) | 2.2–3.2 kHz, rings 172–190 ms, peaks scattered 462–2176 Hz | Lovely idea, lossy and resonant |
| Pebbles on wood | [704379](https://freesound.org/people/ellie.vanderlip/sounds/704379/) | ellie.vanderlip (8525021) | WAV 44.1/16 stereo, 47 s | Small round pebbles dropped on a hardwood floor | 40+ hits, bounces, varied | Bounces double the hits; cut the first impacts only |
| **Fingertip on wood** | [452621](https://freesound.org/people/kyles/sounds/452621/) | kyles (612689) | WAV 48/24 mono, 24 s | Finger taps on a wooden counter, gated | 38 taps, 10–90 ms to −30 dB, centroid 0.1–0.4 kHz (dark), unpitched, M max −32.9 | **Space.** Very dark: [I] laptop speakers roll off in the low hundreds of Hz, so check on the built-in speakers |
| Fingertip on wood | [391918](https://freesound.org/people/Trancox/sounds/391918/) | Trancox (7066974) | WAV 44.1/24 stereo, 6.7 s | Finger tapping wood | 20 taps, 28–52 ms, dark, M max −26.8 | Fallback |
| Felt | [848748](https://freesound.org/people/emapuree/sounds/848748/) | emapuree (12884759) | WAV 48/16 stereo, 0.22 s | "Tap of a wooden block on felt" (uploaded 2026-03-22) | One take, 38 ms, dark, M max −27.3 | One take only |
| Woodblock, soft | VCSL `Woodblock/wood_click_pp_rr1–3`, `wood_click_mp`, `wood_click3_vl1–2` | Versilian Studios, CC0-1.0 ([repo](https://github.com/sgossner/VCSL), commit `c1ea7bc`, 2026-01-14) | WAV 44.1/24 stereo, 0.31–0.92 s | An orchestral woodblock, pp/mp, round robins | 1.4 kHz, 0 % >5k, 86–188 ms, **pitched 1,364–1,397 Hz, salience 0.3–0.7**, M max −27.3 | The "Wood" variant: peak at −11 dBFS, jitter ≤ ±0.5 % |
| Woodblock, soft | [692828](https://freesound.org/people/hollandm/sounds/692828/) | hollandm (5309408) | WAV 44.1/16 stereo, 0.5 s | One soft stick hit on a woodblock, EQ and compression added | 1.9 kHz, 44 ms, pitched 1,656 Hz (0.74), M max −30.7 | One take |
| Temple block | [607215](https://freesound.org/people/jonopodmore/sounds/607215/) | jonopodmore (541139) | WAV 44.1/24 stereo, 1.8 s | A small mokugyo ("wooden fish") from Kōya-san, cloth-covered beater; AKG 414 | 1.8 kHz, 48 ms, pitched 1,839 Hz (0.69), M max −28.8 | Return alternative |
| **Slit drum, low** | VCSL `Slit Drum/LogDrumLo_MedM_v1–v3_rr1_Sum`, `LogDrumHi_…` | Versilian Studios, CC0-1.0 | WAV 44.1/16 stereo, 1.1–1.5 s | A log drum, medium mallet | Lo: 183 Hz, 188 ms to −30 dB, M max −24.1 at 200 ms; Hi: 155 Hz, 414 ms, −21.6 | **Return**: peak −10 dBFS gives −28.1, the Keychron Return's −28.3 |
| Paper | [155626](https://freesound.org/people/Captaingerbear/sounds/155626/) | Captaingerbear (592811) | WAV 44.1/16 mono, 90 s | A pencil eraser, a nail file, a straw wrapper and a hole punch tapped on heavy paper | 40 hits, dark, 12–556 ms, floor −62 dBFS | Mixed objects; the eraser taps fit, if they can be found by ear |
| Paper tube | [140694](https://freesound.org/people/afleetingspeck/sounds/140694/) | afleetingspeck (2522406) | WAV 96/24 stereo, 14.5 s | A finger flicking a paper tube | Pitched 471 and 708 Hz (two notes) | Tonal: no |
| Bamboo stick | [386888](https://freesound.org/people/michorvath/sounds/386888/) | michorvath (3094998) | WAV 44.1/16 mono, 0.57 s | A small bamboo stick on a table | 3.6 kHz, 21–27 % >5k, 46 ms | Bright |

Others: Kenney "Impact Sounds" (CC0, 130 files, 2019, [page](https://kenney.nl/assets/impact-sounds)). Its download is
behind a script, so file names and format are UNVERIFIED; Kenney's audio packs are Ogg only (*sounds.md* §3.8).

### 4.4 Return and the send in this register

**Return (`paragraph`)** comes after a sentence, in the planning pause (DESIGN C1's reason against a bell there).
Options:
- a lower, rounder wooden sound with no ring: the VCSL slit drum low (183 Hz, 188 ms);
- the mokugyo (1.8 kHz, 48 ms);
- or the letter tap a step heavier (rate 0.9, +2 dB).

[I] One fixed pitch per Return, rare and short: not a sequence. Give it no jitter.

**The send (⌘⏎, only when a paste goes out: P1)** marks the end of the writing. Options:
- **Single soft chime** (e.g. VCSL Hand Chimes `sus_E4_r01_main`, 661 Hz, salience 0.94; or `sus_C5`, 1,048 Hz):
  - It is tonal, but one-shot, one fixed note every time, and it plays after the words are written. The
    changing-state literature is about sequences heard *while* holding verbal material; a single tone between tasks is
    not that case.
  - What remains: it rings into the first seconds in the target app; VCSL's hand chime takes 2.5 s to fall 30 dB.
  - [I] Cut it to 0.9 s with a 400 ms fade.
  - [M] At −6 dBFS peak that cut is M max −14.2 LUFS, about 17 LU louder than the Keychron send (−30.8 as cut). A
    ringing tone carries far more energy per peak than a click. Its peak must sit near −20 dBFS, which breaks K1's
    "peaks at −6 dBFS, no gain".
  - Other CC0 single strikes: singing bowl, soft mallet ([415141](https://freesound.org/people/s-light/sounds/415141/),
    s-light, 48/24, 182/519/967 Hz per the uploader, M max −18.6 at 900 ms); Tibetan bell "B"
    ([346328](https://freesound.org/people/steaq/sounds/346328/), 44.1/16, rings 7.9 s, −30.2); singing bowl
    ([707797](https://freesound.org/people/TheGreenEyedGhost/sounds/707797/), 48/24, 946 Hz, −10.4); tingsha
    ([435074](https://freesound.org/people/steffcaffrey/sounds/435074/), 2.9 kHz, bright).
- **Wooden send:** the slit drum high and low as a falling pair, or the mokugyo struck twice. A shishi-odoshi
  ([58569](https://freesound.org/people/morgantj/sounds/58569/), morgantj, **CC BY 4.0**, MP3 at source) is the
  garden's own "release" sound.
- [I] **Pick: the single soft chime**, if the user accepts one tonal sound per hand-off. It is the theme's one moment
  of tone, and it is unlike the Return, so a Copy (which plays the Return, P1) is never mistaken for a send.

## 5. How a theme binds sound

- `architecture.md` §2 recommends a **preset**: choosing a theme writes the pack, the bed and the ambience into today's
  keys, and the menus keep overriding until the next theme switch. For sound that fits as it is:
  - **Send:** comes with the pack (S1, one `send` sample per `pack.json`); a theme names a pack, not a send.
  - **Bed:** a new key (`bed`), a second radio group in Session › Sound ▸ (architecture §4).
  - **⌘K:** silences pack and bed together.
  - **Level:** one per bed (normalised offline to −46 or −48 LUFS), not per theme, so a theme switch changes no
    loudness.
- [I] What a theme should not do: start the bed without the user having chosen the theme (D0's "Off at first" spirit).
  A theme that turns a bed on says so in its menu item, e.g. "Mindful (rain)".
- [I] OmmWriter keeps tracks, backgrounds and key sounds as independent menus (reviews above). Lemna's preset gives one
  coherent choice and keeps the per-axis menus, which is the better of both.

## 6. Method [M]

- **Sources:**
  - HQ previews from the CDN, decoded with ffmpeg to 48 kHz mono float (stereo for loop tests).
  - Long files measured over their first 3 MB unless "full".
- **Loudness:** ffmpeg `ebur128`: integrated (I), loudness range (LRA), true peak (TP).
  - **S-SD:** the SD of the 3 s short-term loudness, sampled every 0.1 s.
  - **Burst:** the share of 400 ms momentary windows more than 6 LU over their median.
- **Spectrum:** shares under 150 Hz (LF) and above 5 kHz (HF), and the centroid, from a Hann-windowed FFT of up to 120 s.
- **Chime onsets:** 10 ms RMS of the signal above 1 kHz, an onset where it rises 9 dB over the previous 50 ms minimum
  and lies 15 dB over the 20th-percentile floor, at most one per 120 ms.
  - **Gaps:** the share of frames 30 dB under the 99.5th percentile.
  - **Tonal peaks:** Welch spectrum peaks of at least 12 dB prominence, 150 Hz–8 kHz.
  - **Ring:** the median time from the 10 loudest maxima to −30 dB, capped at 4 s.
- **Hit analysis:** as §4.3.
- **Typing stream:** Keychron `letter-1…6` and `space-1/2` at gain 0.6, exponential gaps above 70 ms, 60 s, 16-bit.
- **Mix check:** the bed scaled to its target I, 10 ms frames, the loudest 10 % of typing frames compared with the bed's
  frames at the same instants, broadband and in two Butterworth bands.
- **Loop test:** a 60 s stretch with its next 3 s overhang crossfaded into the head on sin/cos ramps, then played twice.
- **AAC:** `afconvert -f m4af -d aac -b <rate>`.
- **Core Audio probe:** a scratch Swift file reading the process list. It was not kept in the repository, and bundle
  ids were not printed.

The previews are lossy; the originals (login) are no worse. The Apple asset was downloaded only to be measured and was
not kept.

## 7. Not verified

- How anything sounds. Nothing was listened to: the motor in 673259, the drips, the felt and stone takes on laptop
  speakers, and the bed level are all for the ear.
- Long recordings beyond their first 90–420 s, except 585845 and 512334.
- How Apple strings its 17 rain clips.
- Background Sounds' default level.
- Kinoton's licence sentence.
- Kenney's file list.
- AirPods switching caused by a bed.
- Power with a bed.
- The first macOS version of the process-object API.
- A sparse chime's effect on writing: no study exists.
- Literature figures marked "as read by the second agent", beyond Newbold 2017 and Proverbio 2018, which I read.

## Recommendations for Lemna

**Verdict on the bed:**
- **Build an optional bed for light rain, and amend D1 for steady nature sound only.**
  - The evidence moves from "lean no" to "neutral, harmless when steady, useful against room speech".
  - Off by default, opt-in through the theme or Session › Sound ▸, stopped by ⌘K and by the close.
  - No promise of focus in the copy.
- **Wind chimes stay out of the writing bed.** They are the changing-state case the evidence warns about, and no
  level makes them safe. If the user still wants them, offer them as the alternative below with that evidence in
  front of them.
- **Do not time strikes to the writer's pauses.** That would put them in the planning pause, where C1 already refused
  a bell (contrary to `architecture.md` §0 Q3's "when no key has come for a while").

**Shortlist (two beds and one alternative):**

| Bed | Source | Cut | Level |
|---|---|---|---|
| **1. Light rain** | felix.blume 585845 (CC0) | A 90 s stretch from 0:30–5:30, loop points by spectral match, 3 s equal-power crossfade baked in; stereo 48 kHz AAC 128 kbit/s, ≈ 1.5 MB; high-pass at 80 Hz | −46 LUFS |
| Light rain, alternates | felix.blume 512334 (CC0; 90 s from 7:33); tim.kahn 169031 (CC BY 4.0, credit "light forest rain by tim.kahn, freesound.org/s/169031, CC BY 4.0, cut and looped") | As above | −46 LUFS |
| **2. Night pond** | felix.blume 673259 (CC0) | 90 s without the motor (by ear), same treatment | −48 LUFS (brighter, 3.2 kHz centroid) |
| Night pond, alternate | parret 481883 (CC0) | As above | −48 LUFS |
| **Alternative (not recommended for writing): Chimes over rain** | One-shot strikes cut from Chris W 432813 (CC0), one chime, its own notes; or a continuous chime drone, be-steele 323047 (CC0), unsegmented | Strikes over bed 1: at most 3 a minute on average, clusters of 1–3, at least 8 s apart, timing random and independent of the keys, each strike ≤ 1.5 s with a fade; or the drone as one loop | Strikes about 6 dB over the rain at the peak, set by ear |

**The mindful click pack "Stone"** (`StonePack`, CC0):

| Kind | Source | Cut and level | Jitter |
|---|---|---|---|
| Letters | worthahep88 319223, 319226, 319227, 319228, each also at rate 0.94: eight samples | 60 ms each: 2 ms lead, 25 ms half-cosine fade, peaks −6 dBFS; M max −31 to −33 LUFS, matched to Keychron | ±3 % (unpitched) |
| Space | kyles 452621, two taps | Peaks set to match the Keychron space by M max | ±3 % |
| Backspace | Two letter takes at rate 0.88 | −6 dB, as the Keychron pack | ±3 % |
| Return | VCSL slit drum low (`LogDrumLo_MedM_v1/v2`) | 200 ms, peak −10 dBFS ≈ −28 LUFS | None |
| Send | VCSL Hand Chimes `sus_E4_r01_main` | 0.9 s with a 400 ms fade, peak ≈ −20 dBFS ≈ −28 LUFS | None |

A "Wood" variant (VCSL woodblock pp and mp, peaks −11 dBFS, no jitter) only if the pitched tick is wanted.

**Engine changes** (on top of `architecture.md` §4's `Bed` source node, about 200 lines):
1. **Per-kind pitch jitter in `pack.json`** (default 0.03; 0 for pitched kinds and tonal packs), read by `Picker`.
   Without it, a tonal tap becomes a random melody.
2. **Sends and other ringing samples levelled by loudness, not peak**: a per-file gain in `pack.json`, or cuts levelled
   offline to the pack's Return (M max). K1's "−6 dBFS, no gain" stays true for clicks only.
3. **Bed files:**
   - stereo 48 kHz AAC, the seam crossfaded offline (3 s, sin/cos), loop points chosen where the 2 s band spectra
     match within about 1 dB;
   - normalised to the bed's target I (−46 / −48 LUFS);
   - THIRD_PARTY.md entries as for the packs: page, licence quote, check date, preview or original SHA-256, cut table.
4. **Memory:** only the chosen bed, decoded at the choice off the main thread, held as 16-bit (17 MB per 90 s stereo)
   and converted in the render, or as Float32 (35 MB).
5. **Lifecycle:**
   - fade in 1.5 s from the show;
   - fade out 0.6 s from the close or ⌘⏎'s key-down;
   - ramp from the current gain on a re-summon;
   - silent (and `isSilence`) while the box is hidden;
   - ⌘K stops both.
6. **Optional, later:** at each summon, read `kAudioHardwarePropertyProcessObjectList` / `kAudioProcessPropertyIsRunningOutput`
   and start the bed 6 dB lower (or not at all) when another app runs output. No prompt on macOS 26 here.
7. **Chimes, only if chosen:** a strike scheduler on the render thread over the bed (Poisson, mean interval ≥ 20 s,
   minimum 8 s, cluster ≤ 3), never driven by key timing.
8. **Before shipping:**
   - test with AirPods (automatic switching);
   - measure power with the bed on and off (`powermetrics`);
   - set every level by ear against the clicks on the built-in speakers and on headphones.
