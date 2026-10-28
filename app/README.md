# Lemna app

The writing surface (DESIGN.md S1 V2 B1 P0), kept in the journal (E2), with key clicks (K1) and the end of a session
(O1 O2 R1), as a macOS app: v1 as planned, then pass 6 (Plan item 6): the surface is a small floating box over
whatever the user is doing (W2) and Done can paste into the app behind it (O3); then pass 7b: a click outside hides
the box (it also brought Harper's suggestions to the review, R2, which pass 9 removed again); then pass 8 (Plan item
8): the caret moves through the text and typing and deleting work anywhere on the line (B4, which replaces B1), with
the journal in format 2; then pass 10: no review, Done pastes at once with R1 applied silently, and the session frame
(M1) is gone; then pass 11: three more click packs and a Sound submenu (K1), the text left on the clipboard after a
paste, the box opaque under Reduce Transparency and the muted grey lighter under Increase Contrast; then pass 12:
the menu-bar mark M3 and the app icon (L1); then pass 13: the name, Lemna (N; Flow was the working name). Swift +
AppKit, SwiftPM with the Command Line Tools only (no Xcode), two package dependencies by path (`../lib/LemnaJournal`,
`../lib/LemnaClicks`), signed with a self-signed certificate or ad-hoc (there is no Developer ID yet).

## Build, run, test

```sh
app/make-cert.sh           # once: a self-signed "Lemna Dev" code-signing certificate in the login keychain
app/make-app.sh            # release build, assembles, signs (Lemna Dev, else Flow Dev, else ad-hoc) and verifies app/build/Lemna.app
(cd app && swift make-icon.swift ../assets/logo/icon-K1.svg build)  # the icon alone: build/AppIcon.iconset, build/AppIcon.icns
open app/build/Lemna.app

cd app
F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
swift test -Xswiftc -F -Xswiftc $F -Xlinker -F -Xlinker $F -Xlinker -rpath -Xlinker $F
```

`swift test` needs the flags because the Command Line Tools ship swift-testing outside the default search path (plain
`swift test` fails with "no such module 'Testing'"; XCTest is not in them at all). They also ship its Foundation
overlay without a module, so no test file imports Foundation and Testing together ("no such module
'_Testing_Foundation'"). `JournalReplayTests` gets by without it: the journal's `URL` is built from the parameter's
own type (`.init(fileURLWithPath:)`), the temporary folder comes from Darwin's `mkdtemp`.

`make-app.sh` copies the click packs (`lib/LemnaClicks/Sources/LemnaClicks/DefaultPack`, `TypewriterPack`, `SoftPack`,
`ElectricPack`, each a `pack.json` and its WAVs) into `Contents/Resources`, where `SoundPack.bundled(<folder>)` loads
them, writes `LSUIElement` (an accessory app from
launch on: no Dock icon, no menu bar) into the Info.plist, and checks the signature with
`codesign --verify --deep --strict`. It runs `make-icon.swift` on the icon SVG named in its `icon=` line (K1 of
`docs/design-panel-icon-round-3.html`), copies `build/AppIcon.icns` into `Contents/Resources` and sets
`CFBundleIconFile` to `AppIcon`. `make-icon.swift` runs with `swift` from the Command Line Tools: `NSImage` reads the
SVG and draws it at iconutil's ten sizes (16 to 1024 px, sRGB), with the drop shadow AppKit's SVG reader leaves out,
and `iconutil -c icns` packs them; the iconset is written afresh each run, and the same SVG gives the same bytes.
`assets/logo/icons.py` writes the three icon SVGs from their numbers.

The tests need no window and no keychain (the journal test keeps its key in memory). `offscreenRenders` draws the
window's content as the app does (1200 × 700 pt at 2×) and writes `app/renders/idle.png`, `glide-0.png`,
`glide-70ms.png`, `glide-140ms.png` (after a new key), `marked.png` (a pending `´` at the caret), `editing.png` (the caret
back in the text, the text after it shown) and `move-left-70ms.png` (70 ms into a ← there); the mark test writes
`mark-M3-1x.png` and `mark-M3-2x.png` (16 and 32 px, black on clear). `app/build/` and `app/renders/` are
git-ignored.

## Layout

- `Sources/LemnaCore` (no AppKit): `Text.swift` the model (one string with `"\n"` between paragraphs and a caret in
  Characters; each key's edits and motion as a `Change`; a journal edit applied, the replay; the line's two parts
  around the caret with ` ¶ `), `Line.swift` the geometry and drawing (Core Text shaping around the caret, the two
  fades, the clips at the caret, caret, the band), `Glide.swift` the glide, `Mechanical.swift`
  the deterministic pass R1, `Session.swift` the end of a session as a state machine, `Summoning.swift` the menu-bar
  mark and when the Bluetooth notice shows, `Sound.swift` the Sound submenu's packs and what ⌘K does (`SoundChoice`), `Box.swift` the box's frame on a screen (`BoxFrame`), which container
  holds the line (`Surface`) and when a click outside hides the box (`ClickOutside`), `Paste.swift` the paste's
  decision table.
- `Sources/Lemna`: `main.swift` the app, window, menus, clicks and the sound toggle, summoning and the two containers
  (`apply()`), a click outside the box, and the end of a session (Done's paste or copy, Copy, Save, Discard, each
  finishing at once); `Box.swift` the box (the non-activating panel, the dim overlays, the line in it); `Paste.swift`
  the pasteboard (Copy's item; since pass 11 nothing is read from it) and the posted ⌘V; `Keeper.swift` the journal in
  the app (open and restore, append, the flushes); `LineView.swift` the view (text input, the keys of B4, edits as
  journal edits and clicks, the two glides, display link); `Strip.swift` the Metal band (Core Graphics into a shared
  buffer, blitted into the drawable); `Frame.swift` the surface's bottom edge (the Bluetooth notice, a hand-off's
  note); `Summon.swift` the hotkey (Carbon) and the menu-bar item with Lemna's menu.
- `Tests/LemnaCoreTests`: the model, the glide, the fades, nothing before the caret drawn right of it, the text after it
  from the caret to 95 %, the renders (`CoreTests`, `RenderTests`); every key of B4, its boundaries, the word rules,
  Characters with é, 🙂 and 👩‍💻, the replay of every key's edits (`EditingTests`); R1's rules, counts and idempotence (`MechanicalTests`); the state machine (`SessionTests`); the
  journal round trip through the app's replay, edits in the middle included (`JournalReplayTests`); the menu-bar mark,
  the Bluetooth notice, the muted colour's contrast (`FrameTests`); the box's frame and its clamps, one container at a
  time, the paste's decision table, the click-outside guard's table (`BoxTests`); the Sound submenu's default, a
  pack's choice and ⌘K (`SoundTests`).

## What it covers

Milestone 1, the surface (the window is window mode since pass 6, below):

- One ordinary resizable window (titled, transparent title bar, standard buttons, minimum 600 × 300, frame
  remembered), so tiling window managers place it; full screen from the green button (⌃⌘F is Open Window since pass
  6). No Edit menu yet.
- The line: Menlo 28 pt, its end at a caret fixed at 60 % of the width, vertically centred; the whole line glides left
  by each key's advance over 140 ms (ease-out cubic, a leftover capped at one advance), and back on backspace; nothing
  is drawn right of the caret (since pass 8: of the text before it); glyphs fade from full strength at 45 % of the width to nothing at 25 %. Reduce Motion
  jumps. A resize lays the line out again.
- The model: paragraphs; Return ends one (twice leaves a blank line), shown on the line as a muted ` ¶ `; backspace only
  within the current word, never past a typed space or a paragraph end (B1; pass 8 replaces this, below).
- Input through `NSTextInputClient`: dead keys and input methods (the pending text is the line's end), the
  press-and-hold accent menu (replaces the letter just typed). Arrows, clicks and other ⌘ shortcuts do nothing (since
  pass 8 the arrows move the caret); Esc hides the box (pass 6) and does nothing in the window.
- Frames: a key draws and presents its frame at once; the display link (up to 120 Hz) runs only while a glide does;
  two drawables in the layer's queue.

Milestone 2 in the app, the journal (E2):

- At launch `Journal.open` in `~/Library/Application Support/Lemna/sessions.noindex/` with the login keychain
  (`KeychainKeyStore()`); the journal creates the folder (0700) and excludes it from backups. The edits of the last
  unfinished session are replayed into the model without a word: the line shows where it ended.
- Every change to the text is one edit: typing `insert`, Return `paragraphEnd`, backspace and the press-and-hold
  replacement `deleteBackward(n)` with `n` in UTF-16 units (format 1; since pass 8 `insert(at:)` and
  `delete(at:count:)` in Characters, below); `Text.apply` is the one path for both typing and the replay, so a restore
  rebuilds the text that was typed. A dead key still pending at Done joins the text as shown.
- Flushes: the journal writes each 50 ms batch itself; the app adds `.full` on 1 s idle (one timer, moved on by each
  edit, on a background queue), on deactivate and on Done (both off the main thread), and on quit
  (`applicationShouldTerminate` waits for it, then terminates).
- ⌘Q quits and keeps the session. (v1: the close button hid the window and the Dock icon brought it back; since pass 6
  the close button returns to the box, and there is no Dock icon.)
- If the journal cannot open (keychain locked or refused, folder not writable), one plain alert says so and writing
  goes on without a journal. Nothing else on the surface.

Milestone 3, the end of a session (O1 O2 R1); its review, R1's undo and the grace went in pass 10 (below):

- Menus: Lemna (About Lemna, a placeholder; Quit ⌘Q), Session (Done ⌘⏎, Copy ⌘⇧⏎, Save… ⌘S, Discard…, Sound ⌘K), View
  (Open Window ⌃⌘F, since pass 6). Done, Copy and Save… are off while the text is blank, a hand-off is under way or
  a question is up. Since pass 6 Lemna shows no menu bar; these menus hold the key equivalents, and the menu-bar item's
  menu shows the items.
- Copy: `prepareForNewContents(with: .currentHostOnly)`, then one pasteboard item with `public.utf8-plain-text` and
  the empty markers `org.nspasteboard.ConcealedType` and `org.nspasteboard.TransientType`.
- Save…: `NSSavePanel` as a sheet on the container, `.md`, named `lemna-YYYY-MM-DD-HHMM.md`, opening in the last folder
  (UserDefaults `SaveFolder`, a path); the text plus a final newline is written with `Data.write(options: .atomic)`.
- Discard… asks once ("Discard this session's text?" / "It cannot be recovered.", Discard / Cancel), then
  `journal.discard()`, the surface clears, a new session starts.
- R1 (`Mechanical.apply`): per paragraph (split at newlines) strips trailing spaces, collapses runs of spaces
  (U+0020 only) to one, capitalises the first letter and the letter after `. `, `! ` or `? `, and makes a lone `i`
  `I` (between white space, brackets, quotes, `'`, closing punctuation; not `i.e.`, `i-th` or inside a word); then
  drops empty paragraphs and joins the rest by a blank line. A period is not taken as a sentence end after a word
  with another period in it (`e.g.`, `z.B.`, an ellipsis), after one letter (`z. B.`, an initial) or after digits
  alone (`3.`, an ordinal). No full stops added, no spelling. Idempotent (tested).

Milestone 4 in the app, the clicks (K1):

- One `ClickPlayer(pack: .bundled())` at launch (since pass 11 `ClickPlayer(packs:)`, below). If it cannot start (no
  output device, the pack missing), Lemna is silent and writes one line to the system log (`Lemna: no key clicks: …`).
- A click on each key that changes the text, played before the edit is laid out and drawn: `.letter` for typed
  characters (and a dead key's pending mark, a key that shows), `.space` for white space, `.paragraph` for Return,
  `.backspace` for a backspace that deletes. A blocked backspace (after a space, at a paragraph's start) is silent, as
  are keys during a hand-off and ⌘ chords. Volume stays at the library's default. (Since pass 8 every delete key
  that deletes clicks `.backspace`; caret moves are silent.)
- Session › Sound (⌘K, and in the menu-bar item) with a check mark, kept in UserDefaults as `sound` (default on). Off
  pauses the engine. (Since pass 11 a submenu of packs, below.)
- Bluetooth: when the output is Bluetooth at launch, after the output device changes, or when the sound is turned on,
  the surface's bottom edge says `Bluetooth output: clicks arrive late · ⌘K mutes` (12 pt system font, `#5c646f`,
  centred, 12 pt above the bottom), once per output, only while the sound is on; it fades out over 1 s after 5 s.

Milestone 5, summoning (W1); the session frame (M1) it also brought went in pass 10:

- Hotkey ⌃⌥Space (`Hotkey` in `Summon.swift`, the one place the chord is defined), registered with Carbon's
  `RegisterEventHotKey`: no permission prompt, works ad-hoc signed. Since pass 6 it toggles the box (below); in window
  mode it does what v1's did: brings the window to the front and makes it key (unhiding the app, restoring a
  minimised window) or, when the window or a sheet on it is already key, hides the app so the app before it comes
  back. If the chord cannot be registered, one line in the system log; the menu-bar item still works.
- Menu-bar item: a template image drawn in code (16 × 16 pt; a 1.5 pt line from x 2 to 14 with a 1.5 × 8.5 pt caret
  bar centred at 60 % of it), so it follows the menu bar's appearance; its menu (since pass 6 all of Lemna's menu):
  Show Lemna (⌃⌥Space shown as its key equivalent), Open Window / Close Window ⌃⌘F, Done ⌘⏎, Copy ⌘⇧⏎, Save… ⌘S,
  Discard…, Sound ✓ ⌘K, Quit Lemna ⌘Q. Done from there brings the box (or the window) forward first.
- v1 kept the regular activation policy (Dock icon) for tiling window managers; pass 6 makes Lemna an accessory app.

Pass 6, the box and paste (W2, O3):

- Accessory app: `LSUIElement` in the Info.plist and `setActivationPolicy(.accessory)` in code; no Dock icon, no menu
  bar (the menu-bar item is the menu). On launch nothing shows.
- The box: an `NSPanel` (`.nonactivatingPanel`, borderless, `canBecomeKey` overridden to true), level `.floating`,
  on all Spaces and as a full-screen auxiliary, transient (left out of Mission Control), `hidesOnDeactivate` off,
  movable by its background, on and off screen at once. Content: `#0e1013`, 10 pt corners, a 1 pt `#262b32` border
  drawn over the content (the line sits 1 pt inside it), the system shadow along the rounded outline;
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
  The bottom edge (the Bluetooth notice, a hand-off's note) is its subview, so it sits at the box's bottom edge
  inside the border. The notice is checked at each summon, so one at launch is not spent unseen.
- Summoning (`Surface`): the hotkey and Show Lemna show the box (recording `NSWorkspace.frontmostApplication` as the
  app to paste into, unless that is Lemna itself) and make it key without activating Lemna, with the dim; again while
  the box has the keys, they hide both. A box left on screen after a click into another app takes the keys back
  (and that app becomes the target). Esc while writing hides the box; the session stays, the journal keeps
  everything, and hiding flushes it fully (as deactivating did). Where Lemna did get activated (window mode, a
  question), hiding hides the app so the app before it comes back.
- Window mode: Open Window (⌃⌘F in the box, or the menu-bar item) hides the box and dim, activates Lemna
  (`NSApp.activate()`, and `activate(ignoringOtherApps:)` 0.2 s later if Lemna is still not active) and shows v1's
  window with the line in it. ⌃⌘F again (Close Window) or the close button returns to the box (out of full screen
  first). Only while writing: a hand-off or question stays with the container it opened on (the close button then
  only hides the window).
- Questions (Discard…, Save…, the journal alert) are sheets on the container on screen; on the box
  Lemna is activated first, since a sheet takes keys only in the active app.
- Paste (O3): ⌘⏎ (Done) in the box, at once since pass 10. `Paste.decide` first: Secure Input on
  (`IsSecureEventInputEnabled`) → copy, note `Secure input is on: copied instead`; no PostEvent permission
  (`CGPreflightPostEventAccess`) → `AXIsProcessTrustedWithOptions` with the prompt option (macOS asks once) and copy,
  `Copied · allow Lemna under Privacy & Security › Accessibility to paste`; no target (none recorded, or it quit) →
  copy, `Copied · no app to paste into`. Else, once Return is up (at most 1 s; a held ⌘⏎ would otherwise auto-repeat
  into the app behind, where it sends messages in many apps): the old pasteboard's items are kept (each type's data,
  as NSPasteboard gives it; nothing when macOS 15.4's pasteboard privacy denies Lemna; until pass 11), the pasteboard
  is written as Copy writes it, the session is finished, the box and dim go, the target is brought forward if it is not in front
  (yield, then `activate(from:)`, then a plain `activate`), and after 120 ms Secure Input is checked again (a password
  field turns it on only once its window has the keys back: then the text stays copied and the box comes back saying
  so); else ⌘V goes out as two `CGEvent`s (`kVK_ANSI_V` down and up, `.maskCommand`, a private event source so held
  keys add no flags) to `.cghidEventTap`. 250 ms later the old items went back if the pasteboard's change count was
  still the one Lemna's write left (until pass 11, which leaves Lemna's text on the clipboard).

Pass 7b, a click outside (W2). The pass also put Harper's suggestions in the review (R2); pass 9 removed them, below.

- Click outside: when the box stops being the key window (`NSWindow.didResignKeyNotification` for the panel), a turn
  later, it hides with the dim as Esc does (the session stays), unless `ClickOutside` holds it: the box is not on
  screen (Esc, the hotkey, a paste, Open Window hid it), a question is up, a sheet hangs on it (Save…, Discard…, an
  alert), or another window of Lemna's has the keys (`NSApp.keyWindow` is then not nil).

Pass 8, editing anywhere on the line (B4, which replaces B1):

- The model (`Text`): one string, a paragraph end as `"\n"` (any newline the input system sends becomes one), and a
  caret counted in Characters, as is everything else: the journal's offsets, the line's parts, the steps of the keys.
  So é, 🙂 and 👩‍💻 are each one ← and one ⌫; a combining accent typed after its letter joins it. The caret's index into
  the string is kept beside the count, so a step of the caret walks one Character; an edit walks the text twice (its
  new count and the caret's index): about 0.2 ms at 35,000 Characters in release, measured, less for shorter texts.
- Keys (`LineView.doCommand`, by the commands AppKit's key bindings send, checked against
  `StandardKeyBinding.dict` and Apple's `NSStandardKeyBindingResponding`): ← → (`moveLeft:`, `moveRight:`) one
  Character, a paragraph end included (← past ` ¶ ` lands before it); ⌥← ⌥→ (`moveWordLeft:`, `moveWordRight:`) over
  white space, then over the word, to its start or its end; ⌘← ⌘→ (they send `moveToLeftEndOfLine:` and
  `moveToRightEndOfLine:`, not `moveToBeginningOfLine:`) to the paragraph's start or end; typing and Return insert at
  the caret; ⌫ (`deleteBackward:`) deletes the Character before the caret anywhere, across spaces and paragraph ends;
  ⌥⌫ (`deleteWordBackward:`) back to where ⌥← lands, ⌦ (`deleteForward:`) the Character after the caret, ⌥⌦
  (`deleteWordForward:`) on to where ⌥→ lands. Words are runs between white space of any kind (⌥Space's no-break space
  and the paragraph end count). The commands that mean the same moves come along (⌃B ⌃F, ⌃⌥B ⌃⌥F;
  `moveToBeginningOfLine:`, `moveToEndOfLine:`, ⌃A ⌃E and ⌥↑ ⌥↓ as paragraph moves; ⌃H and ⌃D send ⌫'s and ⌦'s
  commands anyway). ⌫ at the start and ⌦ at the end, and a move with nowhere to go, do nothing: no click, no edit, no
  frame. ↑, ↓, ⇧ selections, ⌘⌫ and every other command still do nothing; so do clicks (no mouse placement), and there
  is no undo on the line.
  `keyDown` lets ⌘← and ⌘→ through to the key bindings; other ⌘ chords stay the menu's.
- Each key returns a `Change`: the journal's edits (none for a move) and the motion the line needs: text added or
  removed before the caret, removed after it, or passed over by the caret.
- The line (`Line.shape`, `Line.draw`): the 200 Characters before the caret, the pending text, and the 200 after it,
  shaped as one line on each key that edits or moves the caret; `Shaped.caret` is the caret's x in it (Core Text's
  offset for that index). The text before the caret ends at the caret's left edge, faded to the left as before (V2) and clipped at the caret; the text
  after it starts at the caret's right edge, full strength to 80 % of the width, fading to nothing at 95 % (by each
  glyph's centre), clipped at the caret and at 95 %. So no glyph is ever drawn on the caret.
- The glides: an insertion glides the text before the caret as before (it emerges from under the caret) and leaves the
  text after it; a deletion before the caret glides it back; a deletion after the caret closes that text up at once. A
  caret move glides the whole text by the width of what the caret passed (140 ms ease-out; Reduce Motion jumps), so the
  caret stays where it is and the text passes under it: a Character crossing the caret is hidden on one side and comes
  out on the other. That glide's remainder is capped at one word (`Line.wordCells`, six cells) and it starts at most
  one band's width away (⌘→ to a far paragraph end slides in rather than starting where nothing is shaped). Both
  glides run together: the part before the caret moves by the sum.
- Input system: the selected and marked ranges sit at the caret (in UTF-16 units, as it counts), the document it reads
  is the text with the pending text at the caret, and the press-and-hold menu's replacement (a range ending at the
  caret) takes the Characters holding those units before the caret, anywhere in the text.
- Journal format 2 (`../lib/LemnaJournal/README.md`, Format): `insert(at:, text)` and `delete(at:, count:)` in
  Characters; moves are not journaled and the replay puts the caret at the end. A session left by a build before pass 8
  (format 1) is restored as its text and moved into a format 2 file without a word.
- Clicks: a letter (or space, or paragraph) click on typing as before, the backspace click on every delete key that
  deletes, nothing on a caret move.

Pass 9, Harper removed (DESIGN.md R1+R3, amended 2026-10-28):

- `lib/FlowHarper`, `Lint.swift`, `Suggestions.swift` and their tests are gone: two package dependencies again, and
  the build needs no Rust toolchain.
- The review went back to pass 6's (one text column, R1's line with Undo / Redo); pass 10 removed it.
- Build: the bundle's executable is 0.89 MB (886,816 bytes; 10.41 MB with Harper); `codesign --verify --deep --strict`
  passes.

Pass 10, no review and no session frame (DESIGN.md O1+O2+O3, R1+R3, W2, E2 amended, M1 removed, 2026-10-28):

- Gone: `Review.swift` (the box's grown review and the window's sheet, R1's Undo / Redo, the footer, the hand-off's
  Undo), `ReviewKey`, `BoxFrame.grown` and `shrunk`, the grace (`Session.grace`, `Handoff`, `undo`, `tick`), the
  duration's wording and the word count, `FlowCore/Frame.swift` (`TimeBox`, `Tone`, `PrivateLog`), the Time box… and
  Intent… sheets, the progress line, the soft end's tone, the log and Show Log.
- The state machine (`Session`): writing → handing off (Done, Copy or Save… under way: the line takes no keys) →
  cleared (pasted, copied or saved: finished at once; or discarded) → writing. A hand-off that did not happen (the
  save panel cancelled, the pasteboard refused) goes back to writing; the key store refusing to let go of the key
  keeps the session, writing goes on and an alert says `Not finished: …`.
- Done (⌘⏎): a pending dead key joins the text, R1 is applied (`Mechanical.apply`, silently: no toggle, no undo),
  then the paste as in pass 6 (`Paste.decide`). Where it copies instead, the session is finished all the same and the
  container stays up with the note at its bottom edge (`EdgeView.showNote`, in the Bluetooth notice's place, 12 pt
  `#5c646f`, no fade); the next key the line takes (not a ⌘ chord), Esc, or the container going clears it. In the
  window ⌘⏎ always copies, `Copied · no app to paste into`. After a paste the next summon shows an empty line.
- Copy (⌘⇧⏎) and Save… (⌘S): R1's text, as in milestone 3; then the session is finished and the container goes (the
  box hides; Lemna hides if it was active, so the app before it comes back). Both in the main menu, so they reach the
  box through its `sendEvent`, and in the menu-bar item's menu. Failures stay on the surface as a note: `Not copied.`,
  `Not pasted.`, `Not saved: …`; the text stays and writing goes on.
- The menu-bar item: Show Lemna ⌃⌥Space, Open Window ⌃⌘F, Done ⌘⏎, Copy ⌘⇧⏎, Save… ⌘S, Discard…, Sound ⌘K, Quit Lemna
  ⌘Q. Discard… asks once, as before.
- Build: the bundle's executable is 0.78 MB (779,680 bytes; 890,448 before); signed with "Flow Dev".

Pass 11, sounds and the clipboard (DESIGN.md K1 amended, F0, G1 H1, I1 in O1+O2+O3 and E2, W2's accessibility,
2026-10-28):

- Packs: `lib/LemnaClicks` holds four, each 12 cuts in a folder with its `pack.json`: the Keychron (`DefaultPack`, as
  before), `TypewriterPack` (a manual typewriter, CC0, low-passed at 3.5 kHz, Return the carriage-return lever),
  `SoftPack` (MacBook Air keys, CC0, Enter and Delete from a FUJITSU board), `ElectricPack` (an electric typewriter,
  CC BY 4.0, its credit line in `pack.json` and in `lib/LemnaClicks/THIRD_PARTY.md`, which records every pack's
  sources, licence checks, commands and measures). `make-app.sh` copies all four into `Contents/Resources`.
- The player: one `ClickPlayer(packs:)` at launch with the four packs in the submenu's order, every sample of every
  pack in its table (48 clicks, 0.54 MB as files); `pack` is the playing pack's index, so a switch is one assignment
  on the main thread: nothing is read, decoded or allocated, and the key handler never waits. A pack that will not
  load leaves Lemna silent, as the one pack did before.
- Session › Sound (and the menu-bar item's Sound) is a submenu: Keychron, Typewriter, Soft, Electric, then Off ⌘K.
  The playing pack has the tick; Off has it while the sound is off (and no pack then). A pack turns the sound on and
  plays from the next key; Off or ⌘K turns it off, and while it is off back on with the last pack
  (`SoundChoice` in LemnaCore). Kept in UserDefaults: `sound` (on or off, as before) and `soundPack` (the folder; none
  or an unknown one is the Keychron). The Bluetooth notice is as before: once per output, while the sound is on.
- Paste (I1): Lemna's text stays on the clipboard after a paste, with the Concealed and Transient markers as before.
  The old clipboard is no longer read before the write or put back 250 ms after the ⌘V (`Clipboard.save`,
  `Clipboard.restore`, `Paste.restores`, `Paste.restoreAfter` are gone), so a ⌘V that did not land is one more ⌘V
  away, and macOS 15.4's paste alert cannot come up.
- Reduce Transparency: the box's alpha is 1 instead of 0.97, read at each show. Increase Contrast: the muted grey
  (the ` ¶ ` on the line, the bottom edge's notice and notes) is #8d95a0, 6.3:1 on the box, instead of #5c646f,
  3.2:1 (`Style.muted(increasedContrast:)`), read each time the box or the window comes on screen.
- Build: the executable is 0.80 MB (798,160 bytes; 779,680 before), `Contents/Resources` 624 KB; signed with "Flow
  Dev".

Pass 12, the mark and the icon (DESIGN.md L1, 2026-10-28):

- The menu-bar mark is M3 of `docs/design-panel-hypha-logo.html`, the tapered line (`StatusMark` in
  `Summoning.swift`), drawn per scale (Q2 of `docs/design-panel-icon-round-2.html`): `draw(in:)` reads the scale from
  the context, and the menu-bar image's drawing handler runs once for each scale. Right of the caret's left edge the
  line is 1.5 pt (y 7.5 to 9). Left of it, at 2× and up, it narrows to a point on the line's middle (y 8.25), as
  M3's SVG; at 1× the bottom edge rises to y 8 at x 4 and the last 2 pt are 1 pt tall against the top edge
  (`StatusMark.tip`), so the left end is one whole row of pixels instead of a grey wisp. The caret as before.
- The app icon: `CFBundleIconFile` `AppIcon`, from `assets/logo/icon-K1.svg` (K1: I1's body, a constant-weight line fading
  in from the left, the caret at 60 %, a dim track right of it; no taper) through `make-icon.swift`. macOS shows it in Finder and System Settings (no
  Dock icon, LSUIElement); macOS 26's IconServices draws it in its own body, not in a grey tile.
- Tests: the mark's test asserts its pixels at 2× (three rows right of the caret; left of it the rows above and
  below the middle alike, each filling steadily toward the caret from nothing at the point; the caret at 60 % and
  1.5 pt wide) and at 1× (the top row whole from end to end, the tip that row alone). The 2× render is pixel for
  pixel AppKit's rendering of `assets/logo/mark-M3.svg`.
- Build: `Contents/Resources` 1,020 KB (624 before: `AppIcon.icns` 393 KB); signed with "Flow Dev".

Pass 13, the name (DESIGN.md N, 2026-10-28):

- Lemna wherever the app shows its name: the menu-bar item's accessibility description, Show Lemna and Quit Lemna in its
  menu, the main menu's Lemna menu (About Lemna, still a placeholder, the standard panel; Quit Lemna), the alerts
  (`Lemna could not open its journal: …`), the paste note
  `Copied · allow Lemna under Privacy & Security › Accessibility to paste`, the save panel's `lemna-YYYY-MM-DD-HHMM.md`,
  the system log's `Lemna: …` lines.
- The bundle: `build/Lemna.app`, `Contents/MacOS/Lemna`, `CFBundleName` `Lemna`, `CFBundleIdentifier` `dev.lemna.app`
  (was `org.flow.app`). The keychain service `dev.lemna.app.session` (`KeychainKeyStore.service`; was
  `org.flow.app.session`), the journal's folder `~/Library/Application Support/Lemna/sessions.noindex/`, the window's
  frame name `Lemna`, the queues `dev.lemna.flush` and `dev.lemna.journal`, the hotkey's Carbon signature `'Lmna'` (the
  chord stays ⌃⌥Space), the line's attribute key `LemnaMuted`, `ClickOutside.hides(…, lemnaHasKeys:)`.
- The modules: `Lemna` (the app), `LemnaCore`, `LemnaCoreTests`, and next door `lib/LemnaJournal` and `lib/LemnaClicks`
  with their tests; the login-keychain test's switch is `LEMNA_KEYCHAIN_TEST=1`.
- Unchanged: the journal's format magic (`FLOWJ2`, `FLOWJ1`, a format and not a name), the pasteboard markers, the
  UserDefaults keys (`sound`, `soundPack`, `SaveFolder`), the hotkey. UserDefaults are kept per bundle id, so the new id
  starts from the defaults.
- Signing: `make-cert.sh` makes "Lemna Dev"; `make-app.sh` signs with "Lemna Dev", else "Flow Dev" (the certificate from
  before the rename, so builds keep their signature until `make-cert.sh` runs again), else ad-hoc with a notice.
- A session Flow left (`Keeper.open`, before `Journal.open`): `Journal.adopt` moves each journal in
  `~/Library/Application Support/Flow/sessions.noindex/` that has a record in it and no lock on it into Lemna's folder,
  and its key from `org.flow.app.session` into `dev.lemna.app.session`: stored first, then the file moved, then the old
  key destroyed, so a crash anywhere leaves what the next open takes up. It runs at each open (launch, and after each
  hand-off), so a session typed into a Flow still running at Lemna's first launch comes along once Flow has quit. A
  session with nothing typed stays with its key, so no keychain question comes for it. Reading the old key is a keychain
  question for Lemna (another signature than the item's); denied, nothing moves, the not-kept alert says why and the
  next open asks again.
- Tests: LemnaJournal's two for `adopt` (a typed session comes along, after a store that would not answer; an empty one
  and one in use stay). Build: the executable is 0.80 MB (803,504 bytes; 798,160 before), signed with "Flow Dev" (no
  "Lemna Dev" yet).

## Known gaps

- Pass 13 is not tried: nothing was launched; nothing showed the new name, the Accessibility prompt for the new id,
  or a Flow session coming along in the real keychain (the tests use a key store in memory).

- Pass 12 is not tried: the mark has not been seen in the real menu bar, nor the icon in Finder or System Settings.

- Pass 11 is not tried, and nothing in its packs was listened to: their filters, spans and levels are by
  measurement (`lib/LemnaClicks/THIRD_PARTY.md`). On a MacBook the Soft pack may double the key under the fingers.

- Pass 10 is not tried (the builder shows no windows; the note was not drawn).
- A paste finishes the session before its ⌘V goes out: if the ⌘V does not land (no text field has the keys in the
  target, the target ignores posted keys), the text is no longer in Lemna, but since pass 11 it is still on the
  clipboard, one ⌘V away. Before pass 11 the old clipboard came back 250 ms after the ⌘V and the text was then
  nowhere; before pass 10 the 10 s grace's Undo covered it. The clipboard the user had before a paste is gone, as
  after any copy.
- Done from the menu-bar item with the box hidden brings the box up first (to record the app in front and to have a
  place for a note), so on a paste it shows for a moment before it goes.
- Pass 8 is not tried (the builder shows no windows; the line was drawn offscreen, `editing.png`,
  `move-left-70ms.png`). Untried: how the glide of a held ← and of ⌘← feels, and whether a Character passing under the
  caret on a move reads as moving or as blinking (the alternative, not clipping during a move, would draw text over the
  caret, which S1 rejected); whether the accent menu and input methods place themselves right with the caret mid-text;
  ⌘← and ⌘→ in the box (they reach the view because the main menu has no item for them).
- A caret move during an insertion's glide moves the Character it passes from one part to the other, and with it from
  the insertion's offset to the move's: it may shift by what remains of that glide, under one advance.
- The text after the caret is shaped up to 200 Characters: in a window wider than about 9,000 pt its fade would end
  early.
- Pass 7b's click outside is not tried (the builder shows no windows). Untried: whether the press-and-hold accent
  menu, an input method's candidate window or the menu-bar item's menu takes key from the box (they should not; if one
  does, a click outside would hide the box while typing or opening the menu).

- Pass 6 is not tried at all (the builder shows no windows): whether `NSTextInputClient` (marked text, the accent
  menu, input methods) works in the non-activating key panel; whether the main menu's key equivalents (⌘⏎ Done, ⌃⌘F,
  ⌘K, ⌘Q) reach the app while it is not active (the box's `sendEvent` hands them to the menu if not); whether
  `.floating` shows over a full-screen app; how sheets look on the borderless box (a question on the 112 pt box hangs
  below its top edge); whether the hotkey with a sheet up on the box brings the sheet back with the box.
- The PostEvent permission is tied to the code signature, and an ad-hoc signature changes with every build: after a
  rebuild macOS may show Lemna as allowed under Accessibility but drop its events. `app/make-cert.sh` (once) puts a
  self-signed "Lemna Dev" certificate in the login keychain and `make-app.sh` signs with it from then on, so the grant
  survives rebuilds. After the switch from ad-hoc, once: `tccutil reset Accessibility dev.lemna.app`, relaunch, paste.
- The target is the app in front at the summon. A click into another app and then back on the box (rather than the
  hotkey) leaves the old target; when the box is the key window of an inactive Lemna, ⌘V goes wherever the keys are
  once the box hides.
- The dim and the box are fitted to the screens at each summon, not while they show: a display plugged in meanwhile
  is not dimmed until the next summon.
- AeroSpace and other tiling window managers: whether they still tile the window of an accessory app is untried (v1
  kept the Dock icon for that).
- Not tried with the window shown (the builder does not open windows): typing feel and latency, 120 Hz on ProMotion,
  live resize, full screen, AeroSpace tiling, dead keys and the accent menu, the save panel, the restore; nor anything
  of milestones 4 and 5 (clicks in the app, the hotkey, the menu-bar item, the bottom edge). DESIGN.md Open 4 and 5 stay open.
- `NSApp.activate()` (macOS 14's cooperative activation) does not promise to activate; since pass 6 window mode
  falls back to `activate(ignoringOtherApps: true)` (to be deprecated) when Lemna is still not active 0.2 s later.
  The box needs no activation.
- ⌃⌥Space is also macOS's default for "Select next source in Input menu" (System Settings › Keyboard › Keyboard
  Shortcuts › Input Sources); where that shortcut is on, it takes the chord.
- An ad-hoc signed rebuild changes the app's signature, so macOS may ask once whether Lemna may use its keychain item
  when a session is restored (not with the "Lemna Dev" certificate, see above). Deny: the "not kept" alert, the old session stays on disk for the next launch.
- If the key store refuses to destroy the key at the end, an alert says "Not finished: …" and the session stays, on
  the line and on disk.
- Journals `open` reports as unreadable (noise of finished sessions) are left on disk.
- Whether a frame presented while one is already waiting for the same refresh replaces it or queues behind it is not
  documented; with two drawables a queue costs at most one frame. Measure if typing during a glide feels behind.
- Pending text from multi-stage input methods (Japanese, Chinese) is drawn as plain text, without the underline or
  the selected clause.
- No accessibility: VoiceOver does not see the text yet.
- The bundle identifier `dev.lemna.app` is for personal builds: lemna.dev belongs to someone else. Change it before a
  public release if a domain of your own exists (DESIGN.md N, X1); a new id resets the Accessibility grant, the
  keychain item's access and the settings, as the rename did.
