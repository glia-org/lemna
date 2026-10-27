# Flow app

The writing surface (DESIGN.md S1 V2 B1 P0), kept in the journal (E2), with key clicks (K1), the session frame (M1),
and the end of a session (O1 O2 R1), as a macOS app: v1 as planned, then pass 6 (Plan item 6): the surface is a small
floating box over whatever the user is doing (W2) and Done can paste into the app behind it (O3). Swift + AppKit,
SwiftPM with the Command Line Tools only (no Xcode), two package dependencies by path (`../lib/FlowJournal`,
`../lib/FlowClicks`), ad-hoc signed (there is no Developer ID yet).

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
`Contents/Resources/DefaultPack`, where `SoundPack.bundled()` loads it, writes `LSUIElement` (an accessory app from
launch on: no Dock icon, no menu bar) into the Info.plist, and checks the signature with
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
  key does in the review, `Box.swift` the box's frame on a screen and grown for the review (`BoxFrame`) and which
  container holds the line (`Surface`), `Paste.swift` the paste's decision table and the restore rule.
- `Sources/Flow`: `main.swift` the app, window, menus, clicks and the sound toggle, summoning and the two containers
  (`apply()`), the session frame, and the end of a session (Done, Back, Copy, Paste, Save, Discard, the grace, the log
  line); `Box.swift` the box (the non-activating panel, the dim overlays, what it holds); `Paste.swift` the pasteboard
  (Copy's item, the old clipboard kept and put back) and the posted ⌘V; `Keeper.swift` the journal in the app (open
  and restore, append, the flushes); `Review.swift` the review's content and its sheet host for the window;
  `LineView.swift` the view (text input, edits as journal edits and clicks, display link); `Strip.swift` the Metal
  band (Core Graphics into a shared buffer, blitted into the drawable); `Frame.swift` the surface's bottom edge (the
  time box's line, the Bluetooth notice) and the Time box… and Intent… sheets; `Summon.swift` the hotkey (Carbon) and
  the menu-bar item with Flow's menu.
- `Tests/FlowCoreTests`: the model, the glide, the fade, nothing drawn right of the caret, the renders (`CoreTests`,
  `RenderTests`); R1's rules, counts and idempotence (`MechanicalTests`); the state machine (`SessionTests`); the
  journal round trip through the app's replay (`JournalReplayTests`); the time box, the tone, the log's line and file,
  the menu-bar mark, the Bluetooth notice, the review's keys (`FrameTests`); the box's frame and its clamps, the review
  growing it from its bottom edge, one container at a time, the paste's decision table, the restore rule, the pasted
  grace (`BoxTests`).

## What it covers

Milestone 1, the surface (the window is window mode since pass 6, below):

- One ordinary resizable window (titled, transparent title bar, standard buttons, minimum 600 × 300, frame
  remembered), so tiling window managers place it; full screen from the green button (⌃⌘F is Open Window since pass
  6). No Edit menu yet.
- The line: Menlo 28 pt, its end at a caret fixed at 60 % of the width, vertically centred; the whole line glides left
  by each key's advance over 140 ms (ease-out cubic, a leftover capped at one advance), and back on backspace; nothing
  is drawn right of the caret; glyphs fade from full strength at 45 % of the width to nothing at 25 %. Reduce Motion
  jumps. A resize lays the line out again.
- The model: paragraphs; Return ends one (twice leaves a blank line), shown on the line as a muted ` ¶ `; backspace only
  within the current word, never past a typed space or a paragraph end.
- Input through `NSTextInputClient`: dead keys and input methods (the pending text is the line's end), the
  press-and-hold accent menu (replaces the letter just typed). Arrows, clicks and other ⌘ shortcuts do nothing; Esc
  hides the box (pass 6) and does nothing in the window.
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
- ⌘Q quits and keeps the session. (v1: the close button hid the window and the Dock icon brought it back; since pass 6
  the close button returns to the box, and there is no Dock icon.)
- If the journal cannot open (keychain locked or refused, folder not writable), one plain alert says so and writing
  goes on without a journal; the review's footer repeats it. Nothing else on the surface.

Milestone 3, the end of a session (O1 O2 R1):

- Menus: Flow (About Flow, a placeholder; Quit ⌘Q), Session (Done ⌘⏎, Discard…, Time box…, Intent…, Sound ⌘K, Show
  Log), View (Open Window ⌃⌘F, since pass 6). Done is off while the text is blank or a review or question is up. Since
  pass 6 Flow shows no menu bar; these menus hold the key equivalents, and the menu-bar item's menu shows the items.
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
  `RegisterEventHotKey`: no permission prompt, works ad-hoc signed. Since pass 6 it toggles the box (below); in window
  mode it does what v1's did: brings the window to the front and makes it key (unhiding the app, restoring a
  minimised window) or, when the window or a sheet on it is already key, hides the app so the app before it comes
  back. If the chord cannot be registered, one line in the system log; the menu-bar item still works.
- Menu-bar item: a template image drawn in code (16 × 16 pt; a 1.5 pt line from x 2 to 14 with a 1.5 × 8.5 pt caret
  bar centred at 60 % of it), so it follows the menu bar's appearance; its menu (since pass 6 all of Flow's menu):
  Show Flow (⌃⌥Space shown as its key equivalent), Open Window / Close Window ⌃⌘F, Done ⌘⏎, Discard…, Time box…,
  Intent…, Sound ✓ ⌘K, Show Log, Quit Flow ⌘Q. Done from there brings the box (or the window) forward first.
- v1 kept the regular activation policy (Dock icon) for tiling window managers; pass 6 makes Flow an accessory app.
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

Pass 6, the box and paste (W2, O3):

- Accessory app: `LSUIElement` in the Info.plist and `setActivationPolicy(.accessory)` in code; no Dock icon, no menu
  bar (the menu-bar item is the menu). On launch nothing shows.
- The box: an `NSPanel` (`.nonactivatingPanel`, borderless, `canBecomeKey` overridden to true), level `.floating`,
  on all Spaces and as a full-screen auxiliary, transient (left out of Mission Control), `hidesOnDeactivate` off,
  movable by its background, on and off screen at once. Content: `#0e1013`, 10 pt corners, a 1 pt `#262b32` border
  drawn over the content (the line and the review sit 1 pt inside it), the system shadow along the rounded outline;
  the whole panel at alpha 0.97 (on the background alone, the opaque Metal band would show as a darker stripe). Size
  (`BoxFrame`): 60 % of the visible frame of the screen with the pointer (at least 600 pt, at most the screen), 4 em
  tall (112 pt at 28 pt: the line's 2 em band with one em above and below), centred across, its centre two thirds of
  the way down, on whole points, inside the visible frame. A box dragged elsewhere goes back to that place at the next
  summon.
- The dim: one borderless window per screen, black at 0.35, transparent to the mouse, one level under the box, the
  box's collection behaviour, on and off with the box at once; fitted to the screens at each summon. The menu bar and
  the Dock stay above it.
- The line: one `LineView`, moved between the box and the window (whichever is on screen); its caret stays at 60 % of
  the container. It draws only while it is on screen (a hidden layer may keep its drawables), and once per show.
  The time box's line and the Bluetooth notice are its subview, so they sit at the box's bottom edge inside the
  border. The notice is checked at each summon, so one at launch is not spent unseen.
- Summoning (`Surface`): the hotkey and Show Flow show the box (recording `NSWorkspace.frontmostApplication` as the
  app to paste into, unless that is Flow itself) and make it key without activating Flow, with the dim; again while
  the box has the keys, they hide both. A box left on screen after a click into another app takes the keys back
  (and that app becomes the target). Esc while writing hides the box; the session stays, the journal keeps
  everything, and hiding flushes it fully (as deactivating did). Where Flow did get activated (window mode, a
  question), hiding hides the app so the app before it comes back.
- Window mode: Open Window (⌃⌘F in the box, or the menu-bar item) hides the box and dim, activates Flow
  (`NSApp.activate()`, and `activate(ignoringOtherApps:)` 0.2 s later if Flow is still not active) and shows v1's
  window with the line in it. ⌃⌘F again (Close Window) or the close button returns to the box (out of full screen
  first). Only while writing: a review or question stays with the container it opened on (the close button then only
  hides the window).
- Review in place: Done in the box grows it upward from its bottom edge to 60 % of the visible height (at least 240
  pt, its top inside the screen) and shows the review's content (the same as the sheet's: intent, text, footer,
  buttons; the 72-character column centred); Back or Esc shrinks it to the line. In the window the review is v1's
  sheet. The two hosts share one content view (`Review`) and its key routing (`handles`, tried from
  `performKeyEquivalent` before the main menu, whose Done shares ⌘⏎, and from `sendEvent`).
- Questions (Discard…, Time box…, Intent…, Save…, the journal alert) are sheets on the container on screen; on the box
  Flow is activated first, since a sheet takes keys only in the active app.
- Paste (O3): in the box's review a Paste button is the rightmost and ⌘⏎ presses it (Copy stays a button; in the
  window ⌘⏎ is Copy). `Paste.decide` first: Secure Input on (`IsSecureEventInputEnabled`) → copy, footer
  `Secure input is on: copied instead`; no PostEvent permission (`CGPreflightPostEventAccess`) →
  `CGRequestPostEventAccess` (macOS asks once) and copy, `Copied · allow Flow under Privacy & Security ›
  Accessibility to paste`; no target (none recorded, or it quit) → copy, `Copied · no app to paste into`. Else, once
  Return is up (at most 1 s; a held ⌘⏎ would otherwise auto-repeat into the app behind, where it sends messages in
  many apps): the old pasteboard's items are kept (each type's data, as NSPasteboard gives it; nothing when macOS
  15.4's pasteboard privacy denies Flow), the pasteboard is written as Copy writes it, the box and dim go, the target
  is brought forward if it is not in front (yield, then `activate(from:)`, then a plain `activate`), and after 120 ms
  Secure Input is checked again (a password field turns it on only once its window has the keys back: then the text
  stays copied and the box comes back saying so); else ⌘V goes out as two `CGEvent`s (`kVK_ANSI_V` down and up,
  `.maskCommand`, a private event source so held keys add no flags) to `.cghidEventTap`. 250 ms later the old items
  go back if the pasteboard's change count is still the one Flow's write left.
- Undo after a paste: the box is hidden, so the grace runs in the background. Summoning within 10 s shows the review
  with `Pasted · Undo (10 s)`; Undo keeps the session and its text (the paste in the other app stays). After the
  grace the session is finished as after Copy (logged, key destroyed) and the next summon shows an empty line.

## Known gaps

- Pass 6 is not tried at all (the builder shows no windows): whether `NSTextInputClient` (marked text, the accent
  menu, input methods) works in the non-activating key panel; whether the main menu's key equivalents (⌘⏎ Done, ⌃⌘F,
  ⌘K, ⌘Q) reach the app while it is not active (the box's `sendEvent` hands them to the menu if not); whether
  `.floating` shows over a full-screen app; how sheets look on the borderless box (a question on the 112 pt box hangs
  below its top edge); whether the hotkey with a sheet up on the box brings the sheet back with the box.
- The PostEvent permission is tied to the code signature, and an ad-hoc signature changes with every build: after a
  rebuild macOS may show Flow as allowed under Accessibility but drop its events. Remove Flow there (−) and paste
  again to be asked anew.
- Keeping the old clipboard reads the general pasteboard. Where macOS (15.4 on) asks before an app reads it
  programmatically, that read may raise the system's paste alert at each paste; with the alert answered Deny, Flow
  leaves its text on the clipboard instead of restoring. Large items (an image) are read in full on the main thread.
- The target is the app in front at the summon. A click into another app and then back on the box (rather than the
  hotkey) leaves the old target; when the box is the key window of an inactive Flow, ⌘V goes wherever the keys are
  once the box hides.
- A click through the dim into another app leaves the box and the dim on screen (nothing hides the box but Esc, the
  hotkey, Show Flow and a paste).
- The dim and the box are fitted to the screens at each summon, not while they show: a display plugged in meanwhile
  is not dimmed until the next summon.
- AeroSpace and other tiling window managers: whether they still tile the window of an accessory app is untried (v1
  kept the Dock icon for that).
- Not tried with the window shown (the builder does not open windows): typing feel and latency, 120 Hz on ProMotion,
  live resize, full screen, AeroSpace tiling, dead keys and the accent menu, the review sheet's look and keys, the
  save panel on the sheet, the restore; nor anything of milestones 4 and 5 (clicks in the app, the hotkey, the
  menu-bar item, the sheets, the bottom edge, the tone, the log). DESIGN.md Open 4 and 5 stay open.
- `NSApp.activate()` (macOS 14's cooperative activation) does not promise to activate; since pass 6 window mode
  falls back to `activate(ignoringOtherApps: true)` (to be deprecated) when Flow is still not active 0.2 s later.
  The box needs no activation.
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
