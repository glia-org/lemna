# Flow app

The writing surface (DESIGN.md S1 V2 B1 P0, W1's window), kept in the journal (E2), with the end of a session (O1 O2
R1), as a macOS app: Swift + AppKit, SwiftPM with the Command Line Tools only (no Xcode), one package dependency
(`../lib/FlowJournal`, by path), ad-hoc signed (there is no Developer ID yet).

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
'_Testing_Foundation'"). `JournalReplayTests` gets by without it: the journal's `URL` is built from the parameter's
own type (`.init(fileURLWithPath:)`), the temporary folder comes from Darwin's `mkdtemp`.

The tests need no window and no keychain (the journal test keeps its key in memory). `offscreenRenders` draws the
window's content as the app does (1200 × 700 pt at 2×) and writes `app/renders/idle.png`, `glide-0.png`,
`glide-70ms.png`, `glide-140ms.png` (after a new key) and `marked.png` (a pending `´` at the caret). `app/build/` and
`app/renders/` are git-ignored.

## Layout

- `Sources/FlowCore` (no AppKit): `Text.swift` the model (paragraphs, typing at the end, Return, backspace within the
  word, `plainText`, the line's tail with ` ¶ `, a journal edit applied, the replay), `Line.swift` the geometry and
  drawing (Core Text shaping, fade, clip at the caret, caret, the band), `Glide.swift` the glide, `Mechanical.swift`
  the deterministic pass R1 and the word count, `Session.swift` the end of a session as a state machine and the
  duration's wording.
- `Sources/Flow`: `main.swift` the app, window, menus and the end of a session (Done, Back, Copy, Save, Discard, the
  grace); `Keeper.swift` the journal in the app (open and restore, append, the flushes); `Review.swift` the review
  sheet; `LineView.swift` the view (text input, edits as journal edits, display link); `Strip.swift` the Metal band
  (Core Graphics into a shared buffer, blitted into the drawable).
- `Tests/FlowCoreTests`: the model, the glide, the fade, nothing drawn right of the caret, the renders (`CoreTests`,
  `RenderTests`); R1's rules, counts and idempotence (`MechanicalTests`); the state machine (`SessionTests`); the
  journal round trip through the app's replay (`JournalReplayTests`).

## What it covers

Milestone 1, the surface:

- One ordinary resizable window (titled, transparent title bar, standard buttons, minimum 600 × 300, frame
  remembered), so tiling window managers place it; full screen from the green button or View ▸ Enter Full Screen
  (⌃⌘F). No Edit menu yet.
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

Milestone 2 in the app, the journal (E2):

- At launch `Journal.open` in `~/Library/Application Support/Flow/sessions.noindex/` with the login keychain
  (`KeychainKeyStore()`); the journal creates the folder (0700) and excludes it from backups. The edits of the last
  unfinished session are replayed into the model without a word: the line shows where it ended.
- Every change to the text is one edit: typing `insert`, Return `paragraphEnd`, backspace and the press-and-hold
  replacement `deleteBackward(n)` with `n` in UTF-16 units; `Text.apply` is the one path for both typing and the
  replay, so a restore rebuilds the text that was typed. A dead key still pending at Done joins the text as shown.
- Flushes: the journal writes each 50 ms batch itself; the app adds `.full` on 1 s idle (one timer, moved on by each
  edit, on a background queue), on deactivate and on Done (both off the main thread), and on quit
  (`applicationShouldTerminate` waits for it, then terminates).
- The close button hides the window; the Dock icon brings it back. ⌘Q quits and keeps the session.
- If the journal cannot open (keychain locked or refused, folder not writable), one plain alert says so and writing
  goes on without a journal; the review's footer repeats it. Nothing else on the surface.

Milestone 3, the end of a session (O1 O2 R1):

- Menus: Flow (About Flow, a placeholder; Quit ⌘Q), Session (Done ⌘⏎, Discard…), View (Enter Full Screen ⌃⌘F).
  Done is off while the text is blank or a review or question is up.
- Done stops the surface (keys do nothing; the line keeps its last frame) and opens the review sheet: the text with R1
  applied, read-only, selectable, scrollable (system font 15 pt, `#d9dde3` on `#14171b`, at most 72 characters a
  line); a footer with `R1 · N fixes: … · Undo` (Undo shows the raw text, Redo the fixed one), the duration and word
  count, the hand-off's line, and the journal's note if there is no journal; the buttons Discard… (left, set apart),
  Back (Esc), Save… (⌘S), Copy (Return, the default).
- Copy: `prepareForNewContents(with: .currentHostOnly)`, then one pasteboard item with `public.utf8-plain-text` and
  the empty markers `org.nspasteboard.ConcealedType` and `org.nspasteboard.TransientType`. The footer says
  `Copied · Undo (10 s)`; after 10 s without Undo the journal is finished (key destroyed, file deleted), the sheet
  closes, the surface clears and a new session starts. Undo keeps the session and the sheet.
- Save…: `NSSavePanel` as a sheet on the review, `.md`, named `flow-YYYY-MM-DD-HHMM.md`, opening in the last folder
  (UserDefaults `SaveFolder`, a path); the text plus a final newline is written with `Data.write(options: .atomic)`;
  then the same 10 s grace. A grace already running is undone while the save panel or the Discard question is up, so
  the session is never finished under a dialog; a save starts a new grace.
- Back closes the sheet and writing goes on; nothing is destroyed, a running grace included.
- Discard… asks once ("Discard this session's text?" / "It cannot be recovered.", Discard / Cancel), then
  `journal.discard()`, the surface clears, a new session starts.
- R1 (`Mechanical.apply`): per paragraph (split at newlines) strips trailing spaces, collapses runs of spaces
  (U+0020 only) to one, capitalises the first letter and the letter after `. `, `! ` or `? `, and makes a lone `i`
  `I` (between white space, brackets, quotes, `'`, closing punctuation; not `i.e.`, `i-th` or inside a word); then
  drops empty paragraphs and joins the rest by a blank line. A period is not taken as a sentence end after a word
  with another period in it (`e.g.`, `z.B.`, an ellipsis), after one letter (`z. B.`, an initial) or after digits
  alone (`3.`, an ordinal). No full stops added, no spelling. Idempotent (tested).

## Known gaps

- Not tried with the window shown (the builder does not open windows): typing feel and latency, 120 Hz on ProMotion,
  live resize, full screen, AeroSpace tiling, dead keys and the accent menu, the review sheet's look and keys, the
  save panel on the sheet, the restore. DESIGN.md Open 4 and 5 stay open.
- An ad-hoc signed rebuild changes the app's signature, so macOS may ask once whether Flow may use its keychain item
  when a session is restored. Deny: the "not kept" alert, the old session stays on disk for the next launch.
- The duration is wall-clock time since the session's first edit (a restored session: since its journal file was
  made), breaks and quits included.
- `Undo (10 s)` names the grace; it does not count down.
- ⌘Q during a grace keeps the session (⌘Q never discards), so it is back at the next launch.
- If the key store refuses to destroy the key at the end, the review says "Not finished: …" and the session stays on
  disk; the next new session may restore it.
- Journals `open` reports as unreadable (noise of finished sessions) are left on disk.
- Whether a frame presented while one is already waiting for the same refresh replaces it or queues behind it is not
  documented; with two drawables a queue costs at most one frame. Measure if typing during a glide feels behind.
- Pending text from multi-stage input methods (Japanese, Chinese) is drawn as plain text, without the underline or
  the selected clause.
- No accessibility: VoiceOver does not see the text yet.
- No sound yet (`lib/FlowClicks` is not wired in), no hotkey or menu-bar item (milestone 5).
- No icon; the bundle identifier `org.flow.app` is a placeholder until the name is chosen.
