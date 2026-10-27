# appkit-line: notes

The AppKit half of the sliding-line spike (`../SPEC.md`). SwiftPM executable, Swift 6.2.1 with the Command Line
Tools only (no Xcode), no package dependencies.

## Run

```sh
cd spikes/appkit-line
swift build -c release                    # binary: .build/release/appkit-line
./build.sh                                # cold build (rm -rf .build), timed; strips a copy; writes ../results/appkit-build.txt
.build/release/appkit-line --bench        # types 300 characters at 12/s, quits, writes ../results/appkit-{summary.txt,keys.csv}
time .build/release/appkit-line --quit-after-first-frame   # launch timing; prints main-to-first-frame, writes nothing
.build/release/appkit-line                # by hand: type, Esc quits (and overwrites the two result files)
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
swift test -Xswiftc -F -Xswiftc $F -Xlinker -F -Xlinker $F -Xlinker -rpath -Xlinker $F   # 8 tests, no window
```

`swift test` needs the flags because the Command Line Tools ship swift-testing outside the default search path
(plain `swift test` fails with "no such module 'Testing'"); XCTest is not in the Command Line Tools at all.

If macOS does not activate the window when it starts from a terminal, `--bench` prints
`waiting for the window to become key; click it` and starts once it is key.

## Numbers measured here (2026-10-27)

| | |
|---|---|
| cold release build (`build.sh`, wall) | 35.0 s and 35.2 s with no other build running; 37.0 s and 44.8 s under higher load (the 44.8 s run beside the GPUI half's `cargo test`). `results/appkit-build.txt` holds the last run (35.0 s); rerun `./build.sh` on a quiet machine for a fresh figure |
| warm rebuild after touching `main.swift` | ≈ 2 s |
| binary, stripped (`strip -o`) | 139,480 bytes (unstripped 194,088) |
| dependencies | 0 packages; links system frameworks and the OS's Swift runtime only (`otool -L`: AppKit, CoreFoundation, CoreGraphics, CoreText, Foundation, Metal, QuartzCore, libobjc, /usr/lib/swift/*) |
| unit tests | 8 of 8 (ease curve, fade per x, backspace within word, ¶ rule, glide continuity and cap, Reduce Motion, percentile) |
| source | `main.swift` 381 lines + `LineCore.swift` 54 (SPEC: ~400 per program) |

Most of the cold build is Clang building the AppKit/Foundation module cache inside `.build`.

## How it works

- `NSApplication` (`.regular`), one titled 1200×700 pt window, background `#0e1013`, dark title bar.
- The `LineView` is a strip across the full width, 2 em tall, centred vertically; its backing layer is a
  `CAMetalLayer` (`.bgra8Unorm`, sRGB, `framebufferOnly = false`). The window's own background fills the rest.
- Per edit: the last 120 characters are shaped once with Core Text (`CTLineCreateWithAttributedString`,
  `CTLineGetGlyphRuns`, `CTRunGetGlyphs/Positions/Advances`, each run's own font).
- Per frame: Core Graphics fills the strip and draws each glyph with `CTFontDrawGlyphs`, its alpha set from the
  fade at the glyph's centre x, into a bitmap context whose memory is a shared `MTLBuffer` (ring of 3); a blit
  encoder copies it into the drawable's texture; `present`, `commit`. `addPresentedHandler` records
  `presentedTime` for the frame, and the first presented frame holding a key's glyph gives that key's `present_ts`.
- Input: `keyDown:` → `interpretKeyEvents`; `NSTextInputClient` with `insertText` (also honours a replacement
  range, so the press-and-hold accent menu works), `setMarkedText`/`unmarkText` (marked text is drawn at the caret
  like ordinary text), `firstRect` (the caret, so the accent and input-method windows sit there); `doCommand` maps
  `deleteBackward:` (within the word), `insertNewline:` (` ¶`) and `cancelOperation:` (Esc quits). These three are
  the standard key bindings for ⌫, Return and Esc (checked in `StandardKeyBinding.dict`).
- Frames: `NSView.displayLink(target:selector:)`, `preferredFrameRateRange` 80–120, preferred 120; unpaused when
  a glide starts, paused after the frame at which it ends, so no frames when idle. Ticks draw at `targetTimestamp`.
  Reduce Motion (`NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`, read per edit): no glide, each edit
  draws at once.

## Clocks

All four stamps are on one clock, no conversion: `CACurrentMediaTime()` is "mach_absolute_time() converted to
seconds" (`CABase.h`); `MTLDrawable.presentedTime` is "the host time that this drawable was presented on screen"
(`MTLDrawable.h`), host time being the same mach clock; `CADisplayLink` timestamps are on it too; `NSEvent.timestamp`
is uptime from the same clock. Checked at run time: `systemUptime − CACurrentMediaTime()` = −1.7e-7 s; the summary
prints it on each run.

## Deviations from the SPEC and from the brief, and why

1. **The glide moves the whole line, the new glyph included.** The SPEC says the new glyph appears "at its final
   position" and the already-written text glides from +advance to 0, and that later keystrokes "add their advance
   to the remaining offset". Read literally (only the older text offset), the new glyph is drawn on top of the
   previous last glyph for the first frames, and on the next keystroke the previous glyph jumps by the remaining
   offset when it joins the older text. One offset for the whole line (painted at caret − width + offset, as in the
   research notes) is the only reading where nothing jumps; the new glyph then appears in the key's first frame at
   its place in the line, just right of the caret, and slides left with the rest. **The GPUI half should use the
   same reading**, or the two halves look different (the measurements are unaffected).
2. **"Never lags more than one keystroke behind"**: a remaining offset in the direction of the new step is capped
   at one step, so the offset is at most two advances. At 12 keys/s the cap never binds (the remainder after 83 ms
   is ≈ 7 % of an advance).
3. **Backspace glides back** the other way (the SPEC does not say); the deleted glyph goes at once.
4. **Text colour** `#d8dce3` (the SPEC gives none). The fade uses each glyph's centre x.
5. **Blit instead of `MTLTexture.replace(region:)`**: the brief suggested `replace`, which is a CPU write that is
   not allowed on a private texture, and the drawable's storage mode is not documented. Drawing straight into a
   shared `MTLBuffer` and copying it with a blit encoder works whatever the storage mode, and saves a CPU copy.
   Checked windowless: rows land upright, alpha per glyph comes out at the expected value.
6. **Display link paused, not removed**: added to the main run loop once and toggled with `isPaused`, rather than
   added and removed per glide. Same effect (no callbacks when idle), less churn.
7. **When a key's frame is drawn.** When idle, the key handler draws and presents at once, so `handled_ts`
   includes that draw and commit. While a glide runs (all bench keys after the first: 83 ms apart, glides 140 ms),
   the key only updates the model and the next display-link tick draws it, so `present − key` includes up to one
   refresh of waiting. This keeps one present per refresh: whether `CAMetalLayer` replaces or queues a second
   present within one refresh is not documented, and queueing would add a frame of latency that grows. GPUI also
   draws on its display-link callback, so the two are comparable.
8. **`--bench` key events**: `NSEvent.keyEvent(...)` with `timestamp = CACurrentMediaTime()` at posting, posted
   with `NSApp.postEvent(_:atStart: false)`, so `key_ts` is when the event entered the app's queue and leaves out
   the keyboard, HID and WindowServer part of a real keystroke. Key codes are US ANSI, but the text input system
   inserts the event's characters, not the key code's (checked windowless: a synthetic event with key code 0 and
   characters "x" inserts "x"), so the keyboard layout does not matter. The bench starts 0.5 s after the first
   frame, quits 0.5 s after the last character, and the summary line `bench text intact` says whether all 300
   characters arrived. The text is fixed in `main.swift` (300 characters; the GPUI half may use another, which
   does not change the measurements for a monospaced ASCII line).
9. **`--quit-after-first-frame`** prints `main-to-first-frame ms` and exits without writing results, so it does not
   overwrite a bench's files. Any other quit (Esc, closing the window, the bench's end) writes them.
10. **Stripped size and cold build time** cannot be known by the binary, so `build.sh` writes them to
    `results/appkit-build.txt` and the summary reads that file. `run-bench.sh` runs a plain `swift build`, so those
    two numbers are from the last `build.sh` run (the size only changes when the source does).
11. **Results folder** is found from `#filePath` at compile time (`spikes/results`); moving the folder needs a
    rebuild.
12. **Swift 5 language mode** (tools 6.2): no strict-concurrency annotations for a throwaway.
13. **Summary labels** follow the GPUI half's (`n:`, `present-key ms p50/p95/max:`, …) so `run-bench.sh` lines the
    rows up; CSV `seq` counts from 1 as there. Extra rows: frames rendered/presented, bench text intact, Reduce
    Motion, clock check. `n` counts keys with a presented frame (keys that changed nothing, such as Esc or ⌫ at a
    word start, are in the CSV with an empty `present_ts` and `method` `none`).

## Not tested here

- **Nothing with the window shown** (by instruction): presented times, frame rate, activation from a terminal.
- **Dead keys** need a hand on the keyboard: synthetic dead-key events do not compose (the text input system
  inserts their characters as they are), so the bench cannot check them. By hand with the ABC/US layout: ⌥E then E
  → `é`, ⌥U then O → `ö`. With a German layout ⌥E types `€`; use ´ then E for `é` (⌥U then O gives `ö` there too).
  Press-and-hold on E should offer the accent menu at the caret.
