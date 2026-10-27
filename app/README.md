# Flow app

The writing surface (DESIGN.md S1 V2 B1 P0, W1's window) as a macOS app: Swift + AppKit, SwiftPM with the Command Line
Tools only (no Xcode), no package dependencies, ad-hoc signed (there is no Developer ID yet).

## Build, run, test

```sh
app/make-app.sh            # release build, assembles and ad-hoc signs app/build/Flow.app, prints its path
open app/build/Flow.app

cd app
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
swift test -Xswiftc -F -Xswiftc $F -Xlinker -F -Xlinker $F -Xlinker -rpath -Xlinker $F
```

`swift test` needs the flags because the Command Line Tools ship swift-testing outside the default search path (plain
`swift test` fails with "no such module 'Testing'"; XCTest is not in them at all). They also ship its Foundation
overlay without a module, so no test file imports Foundation and Testing together ("no such module
'_Testing_Foundation'").

The tests need no window. `offscreenRenders` draws the window's content as the app does (1200 × 700 pt at 2×) and writes
`app/renders/idle.png`, `glide-0.png`, `glide-70ms.png`, `glide-140ms.png` (after a new key) and `marked.png` (a
pending `´` at the caret). `app/build/` and `app/renders/` are git-ignored.

## Layout

- `Sources/FlowCore` (no AppKit): `Text.swift` the model (paragraphs, typing at the end, Return, backspace within the
  word, `plainText`, the line's tail with ` ¶ `), `Line.swift` the geometry and drawing (Core Text shaping, fade, clip at
  the caret, caret, the band), `Glide.swift` the glide.
- `Sources/Flow`: `main.swift` the app, window and menu; `LineView.swift` the view (text input, edits, display link);
  `Strip.swift` the Metal band (Core Graphics into a shared buffer, blitted into the drawable).
- `Tests/FlowCoreTests`: the model, the glide, the fade, nothing drawn right of the caret, the renders.

## What milestone 1 covers

- One ordinary resizable window (titled, transparent title bar, standard buttons, minimum 600 × 300, frame
  remembered), so tiling window managers place it; full screen from the green button or View ▸ Enter Full Screen
  (⌃⌘F). Menu: Quit (⌘Q) and that item; no Edit menu yet. Closing the window quits.
- The line: Menlo 28 pt, its end at a caret fixed at 60 % of the width, vertically centred; the whole line glides left
  by each key's advance over 140 ms (ease-out cubic, a leftover capped at one advance), and back on backspace; nothing
  is drawn right of the caret; glyphs fade from full strength at 45 % of the width to nothing at 25 %. Reduce Motion
  jumps. A resize lays the line out again.
- The model: paragraphs; Return ends one (twice leaves a blank line), shown on the line as a muted ` ¶ `; backspace only
  within the current word, never past a typed space or a paragraph end.
- Input through `NSTextInputClient`: dead keys and input methods (the pending text is the line's end), the
  press-and-hold accent menu (replaces the letter just typed). Esc, arrows, clicks and other ⌘ shortcuts do nothing.
- Frames: a key draws and presents its frame at once; the display link (up to 120 Hz) runs only while a glide does;
  two drawables in the layer's queue.

## Known gaps

- Nothing is kept: closing the window or ⌘Q loses the text. The journal is milestone 2.
- Not tried with the window shown (the builder does not open windows): typing feel and latency, 120 Hz on ProMotion,
  live resize, full screen, AeroSpace tiling, dead keys and the accent menu. DESIGN.md Open 4 and 5 stay open.
- Whether a frame presented while one is already waiting for the same refresh replaces it or queues behind it is not
  documented; with two drawables a queue costs at most one frame. Measure if typing during a glide feels behind.
- Pending text from multi-stage input methods (Japanese, Chinese) is drawn as plain text, without the underline or
  the selected clause.
- No accessibility: VoiceOver does not see the text yet.
- No icon; the bundle identifier `org.flow.app` is a placeholder until the name is chosen.
