# A send-off sound for Lemna, as of 2026-10-30

Scope: a sound for ⌘⏎ (Done: the text pasted into the app behind), in the material of the chosen sound pack, beside the
four packs of `lib/LemnaClicks` (Keychron, Typewriter, Soft, Electric; `THIRD_PARTY.md`). What makes a "sent" sound
satisfying, one source recording per pack, whether ⌘⇧⏎ (Copy) should sound different, and how loud a send should be next
to the clicks (volume 0.6, mono, ±3 % rate). The rulings of `research_notes/Flow sounds and ambience/sounds.md` and
DESIGN K1 stand: no bell (C1), no ambient bed (D1), no key-up sounds on ordinary keys (U1), no notes or water drops.

Tags as in `sounds.md`: **[E]** controlled study; **[P]** practice, vendor statement, forum; **[M]** my measurement
(method in §6); **[I]** inference. **UNVERIFIED** marks what I could not check. Freesound licences were read on each
sound's page on 2026-10-30. Nothing here was listened to.

## Takeaway

1. **The sent sounds of Apple's own apps are longer than a click and swell:** Messages' "Sent Message" is active for
   ≈ 320 ms, peaks at 220 ms and rises ≈ 4.7 semitones; Mail's "Mail Sent" swoosh is active ≈ 1 s with its peak at
   310 ms; both are dark (centroid 0.4–1.1 kHz) [M]. Apple's sound designer: sync sound to the motion (±10 ms matters),
   keep UI sounds far quieter than notifications, use them sparingly [P]. Mail stores its sent sound 8.5 LU below its
   new-mail alert [M].
2. **Every pack has a recording of its own "send" in the same material**, all from the uploaders and recordings the
   packs already use: Keychron's Enter take holds the key's release 97 ms after the press (the paragraph click is cut
   before it); the FUJITSU Enter take holds its release 116 ms after the press; moodyfingers' "Margin Release and
   Carriage Return" holds the carriage's run and its stop; magedu's electric return runs 1.3 s from the clutch to the
   margin stop. Three are CC0, Electric CC BY 4.0 (already credited, same file).
3. **The arrival can land on the motion's end.** From ⌘⏎'s key-down: Return comes up at ≈ 100 ms for a tap, ⌘V goes out
   ≈ 35 ms later, the hand-off motion ends at 260 ms (HANDOFF, DESIGN F1). The keyboard packs' press + release end
   by ≈ 240 ms as recorded; the typewriters' stop can be put at ≈ 250 ms by starting the cut late in the carriage's run
   (manual) or splicing the clutch's impact onto the run's end (electric).
4. **Copy (⌘⇧⏎) should sound different, in the same family:** the press only, i.e. the pack's existing `paragraph`
   sample (on the Typewriter the platen ratchet, which rolls the paper up as Copy's glyphs rise). And a ⌘⏎ that copies
   instead of pasting plays Copy's sound, not the send: a "sent" sound when nothing was pasted is what users called
   "deceiving" in Mail on iOS 6 [P].
5. **Loudness:** peaks at −6 dBFS like every click, no extra gain; measured, the cuts below land 0.2–0.5 LU above
   (Keychron, Soft) or 1.3–2.8 LU below (Electric, Typewriter) their pack's Return and 4–7 LU above its letters
   (Electric: level with them, its letters being as loud as its Return), from length alone [M].

## 1. What makes a "sent" sound satisfying

### 1.1 What Apple's sounds measure [M]

The files shipped with macOS 26 (Darwin 25.5), decoded to 48 kHz mono. Active = frames within 30 dB of the loudest
10 ms frame. M max = the loudest 400 ms momentary loudness (EBU R128, K-weighted).

| Sound (file) | Active | Loudest at | Gesture | Centroid | M max |
|---|---|---|---|---|---|
| Messages, sent (`/System/Library/PrivateFrameworks/IMDaemonCore.framework/…/Sent Message.aiff`) | 60–380 ms | 220 ms | crescendo over ≈ 200 ms, then −26 dB in 140 ms; spectral peak 0.35 → 0.46 kHz (rising ≈ 4.7 st) | 0.4–0.5 kHz | −24.9 LUFS |
| System sent (`…/CoreAudio.component/…/SystemSounds/system/SentMessage.caf`) | 90–360 ms | 230 ms | the same shape, 0.35 → 0.46 kHz | 0.4–0.5 kHz | – |
| Mail, sent (`/System/Applications/Mail.app/Contents/Resources/Mail Sent.aiff`) | 30–1020 ms | 310 ms | broadband swoosh, +15 dB over 300 ms, then a long fall | 0.9–1.2 kHz | −29.1 LUFS |
| Mail, new mail (`New Mail.aiff`) | – | – | – | – | −20.6 LUFS |
| Dock, poof (`…/SystemSounds/dock/poof item off dock.aif`) | 10–240 ms | 70 ms | rising 0.52 → 0.78 kHz | 0.7–0.8 kHz | – |
| Apple Pay success (`…/SystemSounds/system/payment_success.aif`) | 10–670 ms | 10 ms | two tones, an octave up (1.18 → 2.35 kHz) | 1.2 → 2.3 kHz | – |
| Tink (`/System/Library/Sounds/Tink.aiff`), for reference | 0–40 ms | 10 ms | a tick | 0.7 kHz | −24.7 LUFS |

So in Apple's set: 250 ms to 1 s, a swell rather than an instant attack for the send, the confirmations rising in pitch
where they have one, dark, and Mail's sent sound 8.5 LU under its new-mail alert. Apple's sounds may not be shipped
(`sounds.md` §3.9); they are measured here only for their shape.

### 1.2 What sound designers say [P]

- Apple, Hugo Verweij (Human Interface team), WWDC 2017 "Designing Sound"
  ([session 803](https://developer.apple.com/videos/play/wwdc2017/803/)): on sync, "it's so much more satisfying when
  everything lines up nicely … pushing it back or forward by as little as ten milliseconds sometimes makes a difference";
  on level, a UI sound "has a much lower volume than a notification sound, because people have their phones in their
  hands"; on restraint, "Silence is golden", "we definitely don't do this for every interaction"; the iOS keyboard:
  "When you type faster, we bring down the volume of the sound ever so slightly"; Apple TV's transitions: "a sense of
  direction, because we have two different sounds. You know if you're moving forward or backward"; the Watch's sounds
  were recorded from its own materials (steel, aluminium, gold) so that they seem "made by the device itself"; of a
  typewriter: "there's something satisfying about the letters hitting the paper". He gives no durations.
- Facebook, Will Littlejohn (head of sound design), on the
  [Twenty Thousand Hertz podcast](https://www.20k.org/episodes/facebook-and-google-pixel): the send and sent sounds
  "sonically have the same characteristics", "little, single little, small, little tiny pops"; the post sound is
  "attached … to the completion of the post and not the action of touching the post"; "the simpler, harmonically,
  things are, the higher their repetitive tolerance". Google's Conor O'Sullivan, same episode: "You never want to play a
  sound just to play a sound." Littlejohn's
  [Medium article](https://medium.com/facebook-design/how-to-enhance-mobile-interactions-with-sound-design-3c3b30e98177)
  (read through a [Chinese translation](https://www.woshipm.com/ucd/1097389.html); the original returned 403): mind each
  sound's length against its visual, its loudness against the product's other sounds ("too loud" makes pleasant sounds
  feel aggressive), and its "repetition tolerance".
- Material Design (Google), [Applying sound to UI](https://m2.material.io/design/sound/applying-sound-to-ui.html) and
  [Sound choreography](https://m2.material.io/design/sound/sound-choreography.html): a hierarchy of brand, hero, alert,
  primary and secondary UX sounds; hero sounds mark important moments, are infrequent, and may be longer; sounds play at a
  consistent loudness by their tier (both pages render only with JavaScript; read through search summaries, wording
  UNVERIFIED).
- Gaver's auditory icons: everyday sounds that stand for computer events by analogy with everyday events (Gaver 1989,
  "The SonicFinder", *Human-Computer Interaction* 4, 67–94, [record](https://research.gold.ac.uk/id/eprint/15061)).
  A carriage running back to the margin is the everyday event closest to "this text is done, sent on".
- When to play: Mail on iOS 6 moved its swoosh from the server's acceptance to the tap of Send; users called it "very
  deceiving" and "a gimmick", since it plays even when the mail stalls
  ([MacRumors, 2012](https://forums.macrumors.com/threads/1453491/)). Facebook went the other way (completion).
- Others: Slack offers a user-chosen sound for "Sending a DM" and none for channel messages
  ([Slack help](https://slack.com/help/articles/201355156)); Gmail plays no send sound on Android or iOS, as far as
  users report ([forum](https://forum.earlybird.club/threads/no-sound-when-sending-an-email.1011842/); no Google
  documentation found, UNVERIFIED).

### 1.3 Evidence on gesture and length [E]

- Pitch direction and valence: no study of UI sounds found. In speech, falling and low contours lean negative and rising
  ones positive, inconsistently, with lexical meaning and culture outweighing acoustics
  ([Leiden dissertation](https://scholarlypublications.universiteitleiden.nl/access/item%3A4283266/view);
  [Cantonese contour study](https://journalpub.escholarship.org/cognitivesciencesociety/article/49669/galley/37631/download);
  both seen through search summaries only, UNVERIFIED). Weak; do not build on it.
- Loudness of short sounds grows with duration up to ≈ 100–200 ms (temporal integration; for 5 ms against long tones up
  to 18–19 dB at moderate levels: [ASA 1995 abstract](https://auditory.org/asamtgs/asa95wsh/2pPP/2pPP35.html);
  [Pedersen 2007](https://vbn.aau.dk/files/549500262/BP_PhDThesis.pdf); figures from search summaries, UNVERIFIED). [I] A 250–450 ms send at a click's peak level is
  heard louder than a 70–120 ms click without any gain.
- Key hold: ≈ 116 ms on average (Dhakal et al. 2018, `sounds.md` §1). The releases found below come 82–116 ms after
  their presses, so a recorded press + release has the timing of a real tap.

### 1.4 What follows for Lemna [I]

- One sound, started on ⌘⏎'s key-down with the motion (T1), chosen after `Paste.decide` (synchronous, in the same
  handler), so a paste gets the send and a copy gets Copy's sound. Completion cannot be heard from outside (the ⌘V is
  posted blind), so Facebook's "on completion" is not available; the decided outcome is.
- Its arrival (a release, a stop) near the motion's end, 200–300 ms, which is where Apple's sent sounds peak too; a tail
  past it is fine, the engine keeps running after the box hides (it pauses only when Sound is Off).
- In the pack's material, as the user asked and as the Watch's sounds are; Off stays silent.

## 2. Candidates per pack

What Sadiquecat's pack [38565](https://freesound.org/people/Sadiquecat/packs/38565/) holds (40 sounds, listed through
its [search page](https://freesound.org/search/?f=pack_grouping:%2238565_Computer%20sounds%22&s=Date+added+(newest+first))):
the Keychron K10 runs (789625–789627), its letters (789628), Enter (789629) and space bar (789630); the MacBook Air M2
keys (799109–799113) and two long MBA/MBP typing sessions (729421, 731368, both Ogg at source); the FUJITSU keys
(799114–799118, 799122–799124); mice, a phone, fans, a boot-up. No separate release recording, no MacBook Enter, nothing
longer of the K10 than its runs.

Previews download without login from `https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader id>-hq.ogg`
(Sadiquecat 5287430, moodyfingers 15504031, magedu 4877562). Three of the four previews below are files the packs were
cut from, their SHA-256 as in `THIRD_PARTY.md` (789629, 799116, 319945); 734314 is new:
`2673ceed8d8841ddf4ec2a5433ffcf2ded99460702a26cc23672a12ab5038575`.
Times are in the source as decoded with the pack's own filter; cuts use `tools/cut_click.py` as the packs do.

### 2.1 Keychron: the Enter key's press and release

| | |
|---|---|
| Sound | Keychron k10 Enter, [789629](https://freesound.org/people/Sadiquecat/sounds/789629/), Sadiquecat, pack 38565 |
| Licence | Creative Commons 0 (checked 2026-10-30), uploader: "Attribution is greatly appreciated but not required" |
| Original | WAV 96 kHz/24-bit stereo, 0.561 s, "Hitting Enter on a Keychron K10 … linear switches", Zoom H2n XY |
| Preview | `https://cdn.freesound.org/previews/789/789629_5287430-hq.ogg` |
| In it [M] | press peak at 0.0169 s; the key's release at ≈ 0.113 s (97 ms later; 12 dB under the press after a 200 Hz high-pass, centroid 1.15 kHz against the press's 1.58 kHz); the body's low thump decays to −40 dBFS (5 ms frames) at ≈ 0.21–0.25 s and −50 dBFS at ≈ 0.29 s. The pack's `paragraph-1` (0.006, 92 ms) ends at 0.107 s, 6 ms before the release |
| Cut | decode as the default pack; `cut_click.py cut 789629.wav send-1.wav 0.006 290 --fade 120 --max 400` (0.015–0.305 s) |
| Measured cut | 290 ms; release at 97 ms; −40 dB at 240 ms; M max −28.0 LUFS (paragraph-1 −28.2, letter-1 −32.2) |

Same keyboard's letters for comparison [M]: releases 72–94 ms after the press, 3–16 dB under it; the space bar's 122 ms
after and 22 dB under. A second take (not the 6 %-slower copy) might sit in the 61/66 WPM runs (789626/789627) if they
contain an Enter: UNVERIFIED. A two-key gesture (⌘ then Return) has no recording: the pack has no modifier take.

### 2.2 Typewriter: the carriage's run and its stop

| | |
|---|---|
| Sound | Silver Typewriter (Margin Release and Carriage Return), [734314](https://freesound.org/people/moodyfingers/sounds/734314/), moodyfingers, pack [40966](https://freesound.org/people/moodyfingers/packs/40966/) |
| Licence | Creative Commons 0 (checked 2026-10-30); the uploader's riders as in `THIRD_PARTY.md` (credit optional; not in prohibited content, not on AI apps or models) |
| Original | FLAC 44.1 kHz/24-bit stereo, 9.829 s; smartphone microphone, noise-reduced, gated (digital silence between sounds) |
| Preview | `https://cdn.freesound.org/previews/734/734314_15504031-hq.ogg` |
| In it [M] (after the pack's 3.5 kHz low-pass) | six margin-release presses (0–6 s); a carriage moved at 6.46–7.4 s without a hard stop; the return at 8.42–9.24 s: the lever 8.42–8.50, the carriage's run 8.59–9.01 (a steady whirr 12–21 dB under the stop), the stop at 9.025 s (raw −16 dB in 10 ms frames, the segment's loudest), −57 dB by 9.15 s, gate at 9.25 s. No bell anywhere in the pack |
| Cut (synced) | `ffmpeg -i 734314-hq.ogg -af "lowpass=f=3500:p=2,atrim=8.78:9.24,asetpts=PTS-STARTPTS,afade=t=in:d=0.03:curve=qsin" -ar 48000 -ac 1 -c:a pcm_s16le 734314-tail.wav`, then `cut_click.py cut 734314-tail.wav send-1.wav 0.0 440 --lead 30 --fade 60 --max 500` |
| Measured cut | 440 ms: the run's last 235 ms faded in over 30 ms, the stop at 257 ms (the cut's peak), −40 dB at 390 ms; M max −25.1 LUFS (paragraph-1 −22.3, letter-1 −31.7) |
| Cut (whole) | `cut_click.py cut 734314.wav send-1.wav 8.425 780 --lead 10 --fade 60 --max 800`: lever, run, stop at 610 ms, −40 dB at 740 ms; M max −24.7 LUFS |

The fade-in is done before `cut_click.py` because the script fades in over 0.5 ms only, which would click in the middle
of the run. The pack's `paragraph` is the lever's ratchet from 734312 (the paper advancing, no travel): the synced cut
starts in the run, so the two do not share a start. The other carriage recordings of the pack (Carriage Return Lever
1–3, 734310–734312, 3.3–4.7 s each, CC0) hold ratchet pulls, not the run.

### 2.3 Soft: the FUJITSU Enter's press and release

| | |
|---|---|
| Sound | FUJITSU Computers Keyboard - Enter key Press Mono, [799116](https://freesound.org/people/Sadiquecat/sounds/799116/), Sadiquecat, pack 38565 |
| Licence | Creative Commons 0 (checked 2026-10-30) |
| Original | WAV 96 kHz/24-bit mono, 0.647 s; Zoom H2n MS, mid only, handheld |
| Preview | `https://cdn.freesound.org/previews/799/799116_5287430-hq.ogg` |
| In it [M] (after the pack's 150 Hz high-pass) | press at ≈ 0.090 s; the release at 0.206 s (116 ms later, the file's loudest sample, centroid 1.1 kHz against the press's 0.2–0.3 kHz); a third tick at 0.240 s (2.2 kHz); −45 dB at 0.29 s. The pack's `paragraph-1` (0.088, 110 ms, lead 8) ends before the release |
| Cut | `cut_click.py cut 799116.wav send-1.wav 0.088 240 --lead 8 --fade 80 --max 300` (≈ 0.082–0.322 s) |
| Measured cut | 240 ms; release at ≈ 124 ms; −40 dB at 210 ms; peak normalisation now lands on the release, so the press sits 2.2 dB under paragraph-1's; M max −27.2 LUFS (paragraph-1 −27.7, letter-1 −33.2) |

The MacBook Air, whose keys are the pack's letters, has no Enter recording. Its letter take 799111 (mid) holds releases
82–88 ms after the press, 4–6 dB under it (1.164 → 1.246 s): a lighter alternative, `cut 799111-mid.wav send-1.wav
1.160 150`, if the FUJITSU board does not belong with the MacBook by ear (`THIRD_PARTY.md` open item 4). The 38-minute
MBA typing session (729421) surely holds Returns but is Ogg at source and unindexed.

### 2.4 Electric: the motor's carriage return to the margin stop

| | |
|---|---|
| Sound | typewriter_electric_return.wav, [319945](https://freesound.org/people/magedu/sounds/319945/), magedu, pack [17107](https://freesound.org/people/magedu/packs/17107/) |
| Licence | Attribution 4.0 (checked 2026-10-30), https://creativecommons.org/licenses/by/4.0/; already in the pack's credit line |
| Original | WAV 96 kHz/24-bit mono, 2.247 s, "the return key of an electric typewriter", Zoom H4n + Rode NTG-3 |
| Preview | `https://cdn.freesound.org/previews/319/319945_4877562-hq.ogg` |
| In it [M] (after the pack's 150 Hz high-pass) | the key at 0.09 s (−32 dB); the clutch's impact at 0.315 s (the file's peak) and a burst to 0.53 s; the carriage's run 0.63–1.55 s, steady, ≈ 19 dB under the impact (20 ms frames); the margin stop at 1.58 s, a dull thud (centroid 0.3 kHz) only 2–5 dB over the run; −60 dB by 1.71 s. The pack's `paragraph` is 0.313 s + 600 ms (impact and the run's start) |
| Cut (synced) | `ffmpeg -i 319945-hq.ogg -filter_complex "[0]highpass=f=150:p=2,asplit[a][b];[a]atrim=0.305:0.45,asetpts=PTS-STARTPTS[x];[b]atrim=1.45:1.76,asetpts=PTS-STARTPTS[y];[x][y]acrossfade=d=0.03:c1=qsin:c2=qsin" -ar 48000 -ac 1 -c:a pcm_s16le 319945-splice.wav`, then `cut_click.py cut 319945-splice.wav send-1.wav 0.0 420 --lead 8 --fade 100 --max 500` |
| Measured cut | 420 ms: impact at 8 ms, its burst to 120 ms, the run's last 130 ms, the stop at ≈ 245 ms (15 dB under the impact), −40 dB at 340 ms; M max −26.8 LUFS (paragraph-1 −25.5, letter-1 −26.6) |
| Cut (whole) | `cut_click.py cut 319945.wav send-1.wav 0.313 1440 --fade 150 --max 1500`: the paragraph's first 600 ms, then the run, the stop at ≈ 1.27 s; M max −25.5 LUFS, the same as paragraph-1, as its loudest 400 ms are the same |

The whole return differs from the paragraph only after 600 ms, and its stop arrives about a second after the text did; the
splice is a made sound (a motor-driven carriage does not get shorter), so the credit line's "Changed for Lemna" gains
"spliced". Other electric returns are other machines with hum (IBM Selectric II 224012, Sears Electric Twelve 807926, both
CC0; `sounds.md` §3.2). Not usable as a send: the pack's `turn_off` (277723, CC BY 4.0, a single bright switch click,
5.5 kHz centroid) and `manual_carriage_ring` (277301: a bell).

### 2.5 Fallback: a gesture made from the pack's own paragraph sample

If a recorded cut does not suit by ear: the pack's `paragraph-1`, plus itself 95 ms later at rate 0.88 and −10 dB as a
"release", mixed into one file, e.g. `ffmpeg -i paragraph-1.wav -i paragraph-1.wav -filter_complex
"[1]asetrate=42240,aresample=48000,volume=-10dB,adelay=95[r];[0][r]amix=inputs=2:normalize=0" send-1.wav` (ends near
200–250 ms). No new source, no new licence; untested. Not needed for any of the four packs, which all have the real
release or stop.

## 3. Send and Copy

- Copy (⌘⇧⏎) leaves the text on the clipboard; the box goes with the glyphs rising (C1). ⌘⏎ also copies when it cannot
  paste (no Accessibility permission, Secure Input, no app behind, the window), and the box stays with the reason.
- Evidence for two related sounds: Apple uses two sounds so "you know if you're moving forward or backward" [P];
  Facebook's send and sent sounds share their characteristics [P]; a sent sound on an unsent mail was called deceiving [P].
- **Recommendation:** Send = the full gesture (§2), Copy = the press alone, which is the pack's existing `paragraph`
  sample: Keychron and Soft the Enter press without its release, Typewriter the ratchet (the paper rolling up, as the
  glyphs rise), Electric the clutch's impact and the run's start. No new file for Copy. A ⌘⏎ decided as `.copy` plays
  Copy's sound, so the ear hears that nothing was pasted before the footer is read. [I] The risk: Copy sounds like typing
  Return; the motion (rise, box gone) tells them apart.

## 4. Loudness

[M], per pack, M max (400 ms momentary loudness) of the shipped clicks and the recommended cuts, all peaking at −6 dBFS:

| Pack | letter-1 | paragraph-1 | send (recommended cut) | send − letter | send − paragraph |
|---|---|---|---|---|---|
| Keychron | −32.2 | −28.2 | −28.0 | +4.2 LU | +0.2 LU |
| Typewriter | −31.7 | −22.3 | −25.1 (synced) | +6.6 LU | −2.8 LU |
| Soft | −33.2 | −27.7 | −27.2 | +6.0 LU | +0.5 LU |
| Electric | −26.6 | −25.5 | −26.8 (splice) | −0.2 LU | −1.3 LU |

- [I] Keep −6 dBFS peaks and no `--gain`: the send's length alone puts it at about Return's level (−2.8 to +0.5 LU)
  and 4–7 LU over a letter in three packs (Electric's letters are as loud as its Return, so there the send sits with
  both). That matches the evidence: a UI confirmation well under an alert (Mail −8.5 LU), one tier above the frequent
  sounds (Material), nothing that makes it "aggressive" (Littlejohn).
- It plays through the same player, so volume 0.6 and the ±3 % rate apply as to any click; ±3 % moves the release or stop
  by ≤ 8 ms, under Apple's 10 ms.
- If a send sounds weak beside Return by ear, `--gain +2` (peak −4 dBFS) is the first step; the Typewriter is the
  likeliest case.

## 5. What it would take (nothing changed)

- `KeyKind` gains `send` and every `pack.json` a `"send": ["send-1.wav"]`: `SoundPack.init` throws on a kind without
  files, so all four packs need one. 4 files, 290 + 440 + 240 + 420 ms at 48 kHz/16-bit mono ≈ 133 KB (the four packs are
  ≈ 541 KB today).
- One voice of the mixer's 16 for ≤ 0.45 s (`Mixer.swift` already allows a 1 s Return).
- `done()` plays `.send` after `Paste.decide` returns `.paste`, and `.paragraph` (Copy's sound) for `.copy`;
  `copyText()` plays `.paragraph`. Esc: nothing. Save…: open, not researched.
- `THIRD_PARTY.md`: a row per pack with the commands above and the preview's SHA-256; Electric's credit line gains
  "spliced" if the splice is used.
- A second take per pack (instead of a 6 %-slower copy) does not exist for any of the four sources; one sample with the
  player's ±3 % is enough for a sound heard once per session.
- U1 (no key-up sounds) is not touched: the release is part of one sample started at key-down. Splitting it to play at
  Return's real key-up would follow the hand, but goes against U1's wording, needs the `ReturnUp` path, and gains
  little: a tap's key-up comes at ≈ 100 ms, where the recorded release already is.

## 6. Method [M]

Freesound HQ previews (Ogg Vorbis; originals need a login, as for the packs), decoded with ffmpeg to 48 kHz mono 16-bit,
with each pack's own filter where stated. Events: 2 ms RMS frames that rise ≥ 10–12 dB over the previous 16 ms, found
after two 200 Hz high-passes (the handheld recorder's or desk's thump below 80 Hz otherwise hides the keys' events);
envelopes in 5–20 ms RMS frames; spectral centroid over 40 ms after a peak (Hann window); the spectral peak per 40 ms for
the pitch glides; momentary loudness from ffmpeg's `ebur128` (`M`, 400 ms), the maximum over the file padded with 0.5 s
of silence. The scripts were throwaway and not kept; the cuts were made with the repository's `cut_click.py` and not
added. Apple's files were measured where macOS keeps them, not copied.

## 7. Not verified

- How any of it sounds: nothing was listened to. The release of the K10 and FUJITSU Enter takes is identified by timing
  (97 and 116 ms after the press) and level, not by ear; the moodyfingers "stop" by its level after the run.
- The noise reduction on moodyfingers' smartphone recordings may smear the run's whirr; the preview is lossy.
- Material's wording (JavaScript-only pages), Littlejohn's article in English (403), Gmail's absence of a send sound.
- Whether the K10 runs contain an Enter press for a second take.

## Recommendation

| Pack | Candidate | Licence | Cut | Why |
|---|---|---|---|---|
| Keychron | Keychron k10 Enter, [789629](https://freesound.org/people/Sadiquecat/sounds/789629/), Sadiquecat | CC0 | `cut 789629.wav send-1.wav 0.006 290 --fade 120 --max 400` (press, release at 97 ms, tail to 240 ms) | The same take as the pack's Return, now with the release thock it was cut before: a whole keystroke, done by the motion's end |
| Typewriter | Silver Typewriter (Margin Release and Carriage Return), [734314](https://freesound.org/people/moodyfingers/sounds/734314/), moodyfingers | CC0 | 8.78–9.24 s, 30 ms fade-in, then `cut … 0.0 440 --lead 30 --fade 60 --max 500` (run, stop at 257 ms) | The carriage running home and hitting the margin is the typewriter's own "line sent"; the stop lands on the motion's end; no bell |
| Soft | FUJITSU Enter key Press Mono, [799116](https://freesound.org/people/Sadiquecat/sounds/799116/), Sadiquecat | CC0 | `cut 799116.wav send-1.wav 0.088 240 --lead 8 --fade 80 --max 300` (press, release at ≈ 124 ms) | The pack's own Return take, press and release; no MacBook Enter exists |
| Electric | typewriter_electric_return.wav, [319945](https://freesound.org/people/magedu/sounds/319945/), magedu | CC BY 4.0 (credited already; add "spliced") | impact 0.305–0.45 s spliced onto the run's end 1.45–1.76 s (30 ms crossfade), then `cut … 0.0 420 --lead 8 --fade 100 --max 500` (stop at ≈ 245 ms) | The machine's real clutch, run and margin stop, with the stop on the motion's end; the whole 1.44 s return is the plain alternative |

Copy (⌘⇧⏎, and a ⌘⏎ that copies) plays the pack's existing `paragraph` sample. All sends at −6 dBFS peak, no extra gain.
