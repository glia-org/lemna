# LemnaClicks

The key click player of Lemna (DESIGN.md K1): a click on key-down in the app's own window, from preloaded
samples, varied per key, through one audio stream that stays open. Five packs: the default (a Keychron K10),
Typewriter, Soft, Electric and Stone; and an ambient bed, light rain, on the same stream. A SwiftPM library,
macOS 14, no dependencies.

## API

```swift
import LemnaClicks

let clicks = try ClickPlayer(pack: SoundPack.bundled())  // starts the engine, loads every sample
let all = try ClickPlayer(packs: ["DefaultPack", "TypewriterPack"].map { try SoundPack.bundled($0) })
all.pack = 1                      // which pack plays: an index, every pack is loaded already
clicks.play(.letter)              // on key-down: .letter, .space, .paragraph (Return), .backspace; .send (⌘⏎'s paste)
clicks.enabled = false            // play() and startBed() do nothing, the bed stops, the engine pauses
clicks.volume = 0.6               // 0–1, the default
clicks.bed = try Bed.bundled("Rain")  // the ambient bed: decoded off the main thread; nil takes it off, frees it
clicks.startBed()                 // fade in over 1.5 s (fadeIn:) from the level it has; before the decode is done too
clicks.stopBed()                  // fade out over 0.6 s (fadeOut:), then silent
clicks.bedVolume = 0.6            // 0–1, the default: every bed at Bed.level (−43 LUFS)
clicks.isBluetoothOutput          // the default output device is Bluetooth (classic or LE)
clicks.onOutputChanged = { … }    // main queue, after the default output device changed
clicks.ioBufferFrames             // the IO buffer the device accepted (128 asked)
```

- `play` is for the key handler, one thread at a time (the main thread). Call it on key-down before layout and
  drawing, so the sound leaves ahead of the picture.
- `isBluetoothOutput` is re-read whenever the default output device changes; Bluetooth headphones play every
  click 120–300 ms late and no code can shorten that, so the app warns once (`onOutputChanged`).
- `init` throws `ClickError` when there is no output device or a file of a pack will not load.
- `pack` switches packs without loading anything (all of them are in the mixer's table from `init`), so it can
  change while typing goes on; the key handler never waits for it.

## How the latency path works

1. `play` picks the sample (a random one of its kind in the playing pack, never the one played before) and a
   playback rate within ±3 % (none for the pack's pitched kinds, below), and pushes the pair into a lock-free
   single-producer, single-consumer ring
   (`Sources/ClickRing`, C11 atomics, because Swift's `Atomic` needs macOS 15). No allocation, no lock, no
   Objective-C call: 0.5–17 µs measured in a release build.
2. The engine calls an `AVAudioSourceNode`'s render block on its audio thread once per IO buffer. The block
   drains the ring, starts each click in a free voice of a 16-voice table (stealing the voice furthest through
   its sample when all are busy) at the head of the buffer it fills, and mixes the voices with linear
   interpolation, which applies each click's rate. Nothing on that thread allocates or takes a lock; the
   block holds the mixer `unowned(unsafe)`, so it does no reference counting either.
3. The node's format is mono at the device's sample rate; the samples were converted to that rate once, at
   load, so the main mixer only spreads them over the output channels.
4. The IO buffer is set to 128 frames (2.7 ms at 48 kHz) with `kAudioDevicePropertyBufferFrameSize` on the
   engine's output unit (AUHAL, global scope, element 0; Apple TN2321), clamped to
   `kAudioDevicePropertyBufferFrameSizeRange` and read back into `ioBufferFrames`. The setting is this
   process's own: another process still reads the device's default of 512. The engine keeps running, so no
   click waits for the hardware to wake; it is asked for 128 again when the output device changes or the
   engine restarts after a configuration change.

So a click leaves within one IO buffer of the key-down, plus the device's output latency and safety offset
(on this Mac's built-in speakers 70 + 74 frames, 3 ms).

Why a source node rather than `AVAudioPlayerNode.scheduleBuffer`: both are heard at the next render cycle, but
`scheduleBuffer` is an Objective-C call into the engine with no promise of being lock- or allocation-free,
clicks that overlap would need a pool of player nodes, and the per-click rate would need a varispeed unit per
node or pre-pitched copies of every sample.

## The bed

A bed is a loop of steady sound under the clicks (sound.md: light rain; no voices, birds or chimes, no events
that would be recognised on every pass). `bed` puts it on the engine as a second `AVAudioSourceNode`, stereo,
at the loop's own rate (the main mixer converts it to the device's); the clicks' node is untouched.

- **Memory:** only the chosen bed. Setting `bed` decodes the whole loop on a background queue (90 s of AAC,
  some 40 ms) into floats, 35 MB, and attaches the node on the main queue; `nil` or another bed detaches it.
  The node's block holds the loop, so the loop goes when the engine lets go of the node, not under a render
  call.
- **Render:** a read, a gain and a wrap per frame: the position runs round the loop by index, the seam having
  been crossfaded when the file was made. Silent (`isSilence`, the loop not moving on) until `startBed`.
- **Fades:** `startBed` and `stopBed` set a target level and a step per frame in one 64-bit atomic
  (`click_fade` in `Sources/ClickRing`, beside the ring); the render thread moves the level straight toward
  the target and applies a quarter sine of it, so a fade in is a sine and a fade out a cosine (equal power),
  and a fade turned back midway goes on from where it is. sound.md §2.4: 1.5 s in at the summon, 0.6 s out at
  the close or the hand-off, the bed silent while the box is hidden; the app calls them.
- **Level:** `bed.json` holds the loop's integrated loudness; the gain puts every bed at `Bed.level`, −43 LUFS
  over its two channels (−46 on each), when `bedVolume` is 0.6. sound.md §2.3 set −46 LUFS 12 LU under the
  clicks' −34 LUFS at 5 keys a second, both measured as one channel; the main mixer plays the mono clicks on
  both channels at full level, so over two channels they make −31 LUFS and the bed's −43 keeps the 12 LU.
- **Off (`enabled = false`, ⌘K):** the bed's level drops to 0 at once and the engine pauses; on again, the
  bed waits for `startBed`.

## Adding a pack

A pack is a folder with clicks and a `pack.json`:

```json
{
  "name": "My switches",
  "licence": "CC0-1.0",
  "source": "https://…",
  "attribution": "…",
  "pitched": ["paragraph", "send"],
  "files": {
    "letter": ["letter-1.wav", "letter-2.wav", "letter-3.wav"],
    "space": ["space-1.wav", "space-2.wav"],
    "paragraph": ["return-1.wav", "return-2.wav"],
    "backspace": ["backspace-1.wav", "backspace-2.wav"],
    "send": ["send-1.wav"]
  }
}
```

Every kind needs at least one file; two or more avoid repeats. `attribution` is optional: the credit line a
licence such as CC BY asks for (the Electric pack's). `pitched` is optional too: the kinds whose sound has a
note one hears (Stone's slit drum and chime). They play at their recorded rate, without the ±3 % that varies
the others, which on a note would make a tune of its repeats (sound.md §4.2); a pack with a note in its
letters lists `letter` too. Any WAV or CAF loads (other rates and stereo are converted), but keep to the
default pack's format: 48 kHz mono 16-bit, at most 150 ms (a paragraph's sound, a carriage return, at most
1 s: paragraphs are rare), the press only. The send, the one sample of `send`, is a whole gesture, 240–440 ms
in four packs (a key's press and release, or a carriage's run and stop) and 900 ms in Stone (a hand chime
that rings).

Levels: the first four packs are levelled by peak (`cut` normalises to -6 dBFS, `--gain` moves a cut from
there), every send at -6 dBFS. Stone is levelled by loudness instead: each kind's cuts get one gain that
brings their mean M max (the loudest 400 ms, EBU R 128) to the default pack's kind, so a pack switch changes
no loudness. The send stands as loud as the pack's Returns (the tests: within 3 LU by M max), which a ringing
tone reaches far below a click's peak (Stone's at -20 dBFS).

`tools/cut_click.py` cuts such clicks from a recording (`hits` lists the key hits, `cut` makes one file, with
`--rate`, `--gain`, `--lead`, `--fade` and `--max`; `splice` joins two spans of a take; see its header); it
needs Python's standard library only. Load a pack with `SoundPack(folder:)`; record where its sounds came from,
their licence and every command that made them in `THIRD_PARTY.md` and `tools/build_packs.sh`.

The packs (`Sources/LemnaClicks/DefaultPack`, `TypewriterPack`, `SoftPack`, `ElectricPack`, `StonePack`) and
the beds (`Sources/LemnaClicks/Beds/<name>`) are not SwiftPM resources: the generated `Bundle.module` writes the
absolute build path into every binary that links the library and stops the process when the bundle is missing.
An app copies the pack folders into `Contents/Resources`, where `SoundPack.bundled(<folder>)` loads them
(`bundled()` is the default pack), and the `Beds` folder as `Contents/Resources/Beds`, where `Bed.bundled(<name>)`
loads one; without them, `bundled` throws `ClickError`. The tests load them from the source tree.

## Adding a bed

A bed is a folder in `Sources/LemnaClicks/Beds` with its loop and a `bed.json`:

```json
{
  "name": "Light rain: night rain in a forest, Brazil",
  "licence": "CC0-1.0",
  "source": "https://…",
  "attribution": "…",
  "file": "rain.caf",
  "lufs": -26.0
}
```

The loop: 48 kHz stereo, 60–120 s of a steady stretch, AAC at 128 kbit/s in CAF (about 1 MB a minute;
`afconvert` writes the frame count exactly, so the loop has no padding; unlike an m4a, no creation time). Its
seam is made offline: the 3 s after the loop's end laid over its head with quarter-sine fades, so the wrap is
seamless and the render a plain wrap-around. `tools/loop_points.py match` lists where to start it: the starts
whose last 2 s and first 2 s (as played) match best in their band spectra (standard library; ffmpeg filters the
bands). `tools/build_packs.sh` holds the rain's commands: the decode through an 80 Hz high-pass, the search, the
crossfade (ffmpeg), the AAC (`afconvert`, macOS) and the loudness for `lufs` (ffmpeg's ebur128 over the loop as
Core Audio decodes it). Record the source, its licence and the loop points in `THIRD_PARTY.md`.

## A theme's pack and bed

A theme names a pack folder and a bed name (`research_notes/Lemna themes/architecture.md` §2, the preset). To
give a new theme its own sound: cut its pack as above, make its bed as above, add both to the app's copy step,
and name them in the theme. Packs are all loaded at launch (`ClickPlayer(packs:)`, a switch is an index); a bed
only when chosen (`bed`).

## Tests

The Command Line Tools keep swift-testing outside the default search path, hence the flags:

```sh
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
swift test -Xswiftc -F -Xswiftc $F -Xlinker -F -Xlinker $F -Xlinker -rpath -Xlinker $F
```

Build first (`swift build --build-tests` with the same flags), then run them with `--skip-build` under `timeout 180`:
an engine test hung in CoreAudio once. The engine tests skip when there is no
output device; one of them clicks audibly (11 clicks at a low volume), `--skip playReturnsInMicroseconds` leaves
it out, and one plays the rain quietly for about a second, `--skip theBedFadesInAndOutOnTheEngine`. Everything
else, the bed's fades and wrap and level included, runs without a sound card. Add `-c release -Xswiftc
-enable-testing` for release timings.
