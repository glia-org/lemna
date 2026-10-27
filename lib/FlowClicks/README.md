# FlowClicks

The key click player of Flow (DESIGN.md K1): a click on key-down in the app's own window, from preloaded
samples, varied per key, through one audio stream that stays open. A SwiftPM library, macOS 14, no
dependencies.

## API

```swift
import FlowClicks

let clicks = try ClickPlayer(pack: SoundPack.bundled())  // starts the engine, loads every sample
clicks.play(.letter)              // on key-down: .letter, .space, .paragraph (Return), .backspace
clicks.enabled = false            // play() does nothing and the engine pauses
clicks.volume = 0.6               // 0–1, the default
clicks.isBluetoothOutput          // the default output device is Bluetooth (classic or LE)
clicks.onOutputChanged = { … }    // main queue, after the default output device changed
clicks.ioBufferFrames             // the IO buffer the device accepted (128 asked)
```

- `play` is for the key handler, one thread at a time (the main thread). Call it on key-down before layout and
  drawing, so the sound leaves ahead of the picture.
- `isBluetoothOutput` is re-read whenever the default output device changes; Bluetooth headphones play every
  click 120–300 ms late and no code can shorten that, so the app warns once (`onOutputChanged`).
- `init` throws `ClickError` when there is no output device or a file of the pack will not load.

## How the latency path works

1. `play` picks the sample (a random one of its kind, never the one played before) and a playback rate within
   ±3 %, and pushes the pair into a lock-free single-producer, single-consumer ring (`Sources/ClickRing`,
   C11 atomics, because Swift's `Atomic` needs macOS 15). No allocation, no lock, no Objective-C call:
   0.5–17 µs measured in a release build.
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

## Adding a pack

A pack is a folder with clicks and a `pack.json`:

```json
{
  "name": "My switches",
  "licence": "CC0-1.0",
  "source": "https://…",
  "files": {
    "letter": ["letter-1.wav", "letter-2.wav", "letter-3.wav"],
    "space": ["space-1.wav", "space-2.wav"],
    "paragraph": ["return-1.wav", "return-2.wav"],
    "backspace": ["backspace-1.wav", "backspace-2.wav"]
  }
}
```

Every kind needs at least one file; two or more avoid repeats. Any WAV or CAF loads (other rates and stereo are
converted), but keep to the default pack's format: 48 kHz mono 16-bit, at most 150 ms, the press only, peaks at
-6 dBFS. `tools/cut_click.py` cuts such clicks from a recording (`hits` lists the key hits, `cut` makes one
file; see its header). Load a pack with `SoundPack(folder:)`; record where its sounds came from and their
licence in `THIRD_PARTY.md`.

The default pack (`Sources/FlowClicks/DefaultPack`) is not a SwiftPM resource: the generated `Bundle.module`
writes the absolute build path into every binary that links the library and stops the process when the bundle
is missing. An app copies the folder into `Contents/Resources/DefaultPack`, where `SoundPack.bundled()` loads
it; without it, `bundled()` throws `ClickError`. The tests load it from the source tree with `SoundPack(folder:)`.

## Tests

The Command Line Tools keep swift-testing outside the default search path, hence the flags:

```sh
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
swift test -Xswiftc -F -Xswiftc $F -Xlinker -F -Xlinker $F -Xlinker -rpath -Xlinker $F
```

The engine tests click audibly (11 clicks at a low volume) and skip when there is no output device. Add
`-c release -Xswiftc -enable-testing` for release timings.
