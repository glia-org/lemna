# Flow app

The writing surface (DESIGN.md S1 V2 B1 P0), kept in the journal (E2), with key clicks (K1), the session frame (M1),
summoning (W1) and the end of a session (O1 O2 R1), as a macOS app: v1 as planned. Swift + AppKit, SwiftPM with the
Command Line Tools only (no Xcode), two package dependencies by path (`../lib/FlowJournal`, `../lib/FlowClicks`),
ad-hoc signed (there is no Developer ID yet).

## Build, run, test

```sh
app/make-app.sh            # release build, assembles, ad-hoc signs and verifies app/build/Flow.app, prints its path
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

`make-app.sh` copies the click pack (`lib/FlowClicks/Sources/FlowClicks/DefaultPack`, `pack.json` and its WAVs) into
`Contents/Resources/DefaultPack`, where `SoundPack.bundled()` loads it, and checks the signature with
`codesign --verify --deep --strict`.

The tests need no window and no keychain (the journal test keeps its key in memory). `offscreenRenders` draws the
window's content as the app does (1200 × 700 pt at 2×) and writes `app/renders/idle.png`, `glide-0.png`,
`glide-70ms.png`, `glide-140ms.png` (after a new key) and `marked.png` (a pending `´` at the caret). `app/build/` and
`app/renders/` are git-ignored.

## Layout

- `Sources/FlowCore` (no AppKit): `Text.swift` the model (paragraphs, typing at the end, Return, backspace within the
  word, `plainText`, the line's tail with ` ¶ `, a journal edit applied, the replay), `Line.swift` the geometry and
  drawing (Core Text shaping, fade, clip at the caret, caret, the band), `Glide.swift` the glide, `Mechanical.swift`
  the deterministic pass R1 and the word count, `Session.swift` the end of a session as a state machine and the
  duration's wording, `Frame.swift` the session frame (the time box's fill and end, the soft end's tone as WAV bytes,
  the private log's line and append), `Summoning.swift` the menu-bar mark, when the Bluetooth notice shows, and what a
  key does in the review sheet.
- `Sources/Flow`: `main.swift` the app, window, menus, clicks and the sound toggle, the session frame, and the end of
  a session (Done, Back, Copy, Save, Discard, the grace, the log line); `Keeper.swift` the journal in the app (open
  and restore, append, the flushes); `Review.swift` the review sheet; `LineView.swift` the view (text input, edits as
  journal edits and clicks, display link); `Strip.swift` the Metal band (Core Graphics into a shared buffer, blitted
  into the drawable); `Frame.swift` the surface's bottom edge (the time box's line, the Bluetooth notice) and the
  Time box… and Intent… sheets; `Summon.swift` the hotkey (Carbon) and the menu-bar item.
- `Tests/FlowCoreTests`: the model, the glide, the fade, nothing drawn right of the caret, the renders (`CoreTests`,
  `RenderTests`); R1's rules, counts and idempotence (`MechanicalTests`); the state machine (`SessionTests`); the
  journal round trip through the app's replay (`JournalReplayTests`); the time box, the tone, the log's line and file,
  the menu-bar mark, the Bluetooth notice, the review's keys (`FrameTests`).

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

- Menus: Flow (About Flow, a placeholder; Quit ⌘Q), Session (Done ⌘⏎, Discard…, Time box…, Intent…, Sound ⌘K, Show
  Log), View (Enter Full Screen ⌃⌘F). Done is off while the text is blank or a review or question is up.
- Done stops the surface (keys do nothing; the line keeps its last frame) and opens the review sheet: the text with R1
  applied, read-only, selectable, scrollable (system font 15 pt, `#d9dde3` on `#14171b`, at most 72 characters a
  line); a footer with `R1 · N fixes: … · Undo` (Undo shows the raw text, Redo the fixed one), the duration and word
  count, the hand-off's line, and the journal's note if there is no journal; the buttons Discard… (left, set apart),
  Back (Esc), Save… (⌘S), Copy (⌘⏎, Done's chord, so ⌘⏎ twice is done and copied; its auto-repeat does not copy).
  Plain Return does nothing (a reflexive Return used to replace the clipboard and start the grace), so Copy is not
  drawn as the default button. The intent, if one was set, heads the sheet in one muted line (13 pt, `#5c646f`).
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

Milestone 4 in the app, the clicks (K1):

- One `ClickPlayer(pack: .bundled())` at launch. If it cannot start (no output device, the pack missing), Flow is
  silent and writes one line to the system log (`Flow: no key clicks: …`).
- A click on each key that changes the text, played before the edit is laid out and drawn: `.letter` for typed
  characters (and a dead key's pending mark, a key that shows), `.space` for white space, `.paragraph` for Return,
  `.backspace` for a backspace that deletes. A blocked backspace (after a space, at a paragraph's start) is silent, as
  are keys while the review is up and ⌘ chords. Volume stays at the library's default.
- Session › Sound (⌘K, and in the menu-bar item) with a check mark, kept in UserDefaults as `sound` (default on). Off
  pauses the engine and also silences the soft end's tone.
- Bluetooth: when the output is Bluetooth at launch, after the output device changes, or when the sound is turned on,
  the surface's bottom edge says `Bluetooth output: clicks arrive late · ⌘K mutes` (12 pt system font, `#5c646f`,
  centred, 12 pt above the bottom), once per output, only while the sound is on; it fades out over 1 s after 5 s.

Milestone 5, summoning (W1) and the session frame (M1):

- Hotkey ⌃⌥Space (`Hotkey` in `Summon.swift`, the one place the chord is defined), registered with Carbon's
  `RegisterEventHotKey`: no permission prompt, works ad-hoc signed. It brings the window to the front and makes it
  key (unhiding the app, restoring a minimised or closed window) or, when Flow's window or a sheet on it is already
  key, hides the app so the app before it comes back. If the chord cannot be registered, one line in the system log;
  the menu-bar item still works.
- Menu-bar item: a template image drawn in code (16 × 16 pt; a 1.5 pt line from x 2 to 14 with a 1.5 × 8.5 pt caret
  bar centred at 60 % of it), so it follows the menu bar's appearance; its menu: Show Flow (⌃⌥Space shown as its
  key equivalent), Done ⌘⏎, Sound ✓ ⌘K, Quit Flow ⌘Q. Done from there brings the window forward first.
- The app keeps the regular activation policy (Dock icon): tiling window managers expect it.
- Session › Time box…: a sheet with Off, 10, 15, 25 minutes (radio buttons), Set / Cancel. The box starts when it is
  set; Set on the running box leaves it running; Set on an ended one starts it again. It lasts for this session only
  (in memory; gone at the session's end or a quit).
- The progress line: with a box, a 1 pt line along the very bottom edge of the surface, track `#262b32`, fill
  `#5c646f`, filling left to right over the box, moved twice a second (a 0.5 s timer, in the common run-loop modes);
  no numbers.
- Soft end: when the box elapses, once, a 440 Hz sine, 300 ms, peak −18 dBFS, 50 ms raised-cosine fades, generated at
  launch as WAV bytes in memory (`Tone.wav`) and played by `NSSound(data:)`; the click player takes only its pack's
  samples, so it cannot play an ad-hoc buffer. No tone while the sound is off or the review is up. The line stays
  full; typing goes on.
- Session › Intent…: a sheet with one text field, at most 120 characters (cut as typed or pasted; newlines become
  spaces). Shown nowhere while writing; heads the review sheet. In memory only: never journaled, never logged, gone at
  the session's end or a quit.
- Private log: when a session is finished (a Copy's or Save's grace ran out; not Discard), one line
  `YYYY-MM-DD\tHH:MM\tminutes\twords\n` is appended to `~/Library/Application Support/Flow/log.tsv` (made 0600, one
  `write` with `O_APPEND`): the session's start in local time, its whole minutes and words as the review showed them
  at Done. Totals only: no text, no timing per key. Session › Show Log reveals the file in Finder (off until it
  exists).

## Known gaps

- Not tried with the window shown (the builder does not open windows): typing feel and latency, 120 Hz on ProMotion,
  live resize, full screen, AeroSpace tiling, dead keys and the accent menu, the review sheet's look and keys, the
  save panel on the sheet, the restore; nor anything of milestones 4 and 5 (clicks in the app, the hotkey, the
  menu-bar item, the sheets, the bottom edge, the tone, the log). DESIGN.md Open 4 and 5 stay open.
- `NSApp.activate()` (macOS 14's cooperative activation) does not promise to activate; whether the hotkey brings
  Flow forward from another app is untried. If it does not, the deprecated `activate(ignoringOtherApps: true)` is the
  fallback.
- ⌃⌥Space is also macOS's default for "Select next source in Input menu" (System Settings › Keyboard › Keyboard
  Shortcuts › Input Sources); where that shortcut is on, it takes the chord.
- The time box runs on the media clock, which stands still while the Mac sleeps: a box resumes after a wake rather
  than ending under a closed lid. The fill's first and last points hide under the window's rounded bottom corners.
- The radio buttons of the Time box sheet are reached by mouse, or by Tab with keyboard navigation on.
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
- No icon; the bundle identifier `org.flow.app` is a placeholder until the name is chosen.
