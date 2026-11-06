# Lemna app

The writing surface (DESIGN.md S1 V2 B1 P0), kept in the journal (E2), with key clicks (K1) and the end of a session
(O1 O2 R1), as a macOS app: v1 as planned, then pass 6 (Plan item 6): the surface is a small floating box over
whatever the user is doing (W2) and Done can paste into the app behind it (O3); then pass 7b: a click outside hides
the box (it also brought Harper's suggestions to the review, R2, which pass 9 removed again); then pass 8 (Plan item
8): the caret moves through the text and typing and deleting work anywhere on the line (B4, which replaces B1), with
the journal in format 2; then pass 10: no review, Done pastes at once with R1 applied silently, and the session frame
(M1) is gone; then pass 11: three more click packs and a Sound submenu (K1), the text left on the clipboard after a
paste, the box opaque under Reduce Transparency and the muted grey lighter under Increase Contrast; then pass 12:
the menu-bar mark M3 and the app icon (L1); then pass 13: the name, Lemna (N; Flow was the working name); then pass 14:
the effects (F1): Tokyo Night's colours, the box's pop, accent border and theme dim, the glide on easeOutQuint, the
glyph pop-in, the sheens, the paragraph fade and Session › Effects ▸; then pass 14b: the effects made plain to see,
their magnitudes in one table, and the colours back to Lemna's own; then pass 15: the ambience (A1), seven scenes on the
dim around the box fed by the keys, on a Metal layer of their own, and Session › Ambience ▸; then pass 15b: the crash at
Esc with a mode on fixed; then pass 16: the ambience plain to see and following where each key is on the keyboard;
then pass 17a: the second between ⌘⏎ and the paste gone, and a timing log of the hand-off; then pass 17b: the
hand-off's motion, the line's glyphs leaving the box from the key-down on (in place of the sheen); then pass 18: the
motion revised, the glyph pop-in a fade, Border warms, Word sheen and the ambience's Beams, Fireworks and Swarm
removed, one curve and one scale of durations; then pass 19a: a send sound per pack at ⌘⏎'s paste, Return's click at
Copy, Save… and a ⌘⏎ that copies; then pass 19b: Rain as the films' rain, a fixed grid lit by stepping heads, falling
from the summon to the close and raised by typing; then pass 20: Start at Login in the menu-bar item's menu; then
pass 21: the theme layer, Session › Theme ▸ with today's look as the theme Lemna and Still as a first light stub.
Swift +
AppKit, SwiftPM with the Command Line Tools only (no Xcode), two package dependencies by path (`../lib/LemnaJournal`,
`../lib/LemnaClicks`) and one Objective-C function of its own (`Sources/LemnaCatch`), signed with a self-signed certificate or ad-hoc (there is no Developer ID yet).

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
`ElectricPack`, `StonePack`, each a `pack.json` and its WAVs) into `Contents/Resources`, where
`SoundPack.bundled(<folder>)` loads them, and the beds (`Beds`, each a `bed.json` and its loop) as
`Contents/Resources/Beds`, where `Bed.bundled(<name>)` loads the one chosen, writes `LSUIElement` (an accessory app from
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
back in the text, the text after it shown) and `move-left-70ms.png` (70 ms into a ← there), and since pass 14
`glide-8ms.png` and `glyph-fade-8ms.png` (the first 120 Hz frame after a key, without and with the glyph fade;
`pop-in-8ms.png` with the pop-in until pass 18) and
`paragraph-25ms.png` and `paragraph-fade-25ms.png` (25 ms after a Return, without and with the ` ¶ `'s fade), and since
pass 15 `ambience-<mode>.png` for each of the modes, four since pass 18 (after 10 s of typing, 0.6 s after a Return,
drawn by the Metal pipeline over a dimmed dark app with the box; skipped without a Metal device), and since pass 16
`ambience-grid-keyboard.png` ("the quick brown fox" at 20 keys/s, the keys lit as a keyboard), and since pass 17b
`handoff-send-60ms.png`, `handoff-send-120ms.png`, `handoff-send-200ms.png` and `handoff-rise-120ms.png` (the box over
a light app 60, 120 and 200 ms after ⌘⏎, and 120 ms after ⌘⇧⏎; composed as Core Animation composes the app's layers),
and since pass 19b `ambience-code-idle.png` (Code at rest, 3 s after the summon, since pass 27b 3 s after its
build-in; `ambience-code.png` is Code typing), and since pass 27b `ambience-code-build-500ms.png` and
`ambience-code-build-2000ms.png` (Code building in, 0.5 s after the summon and at half its build-in),
and since pass 21 `ambience-code-still-day.png` (Code at rest on Still's day wash over a light app),
`ambience-code-still-night.png` (on its night wash over a dark app), `idle-still-day.png` and `idle-still-night.png`
(the four `ambience-code*` named `ambience-rain*` until pass 25), and since pass 24 `ambience-water-day.png` and
`ambience-water-night.png` (Still water on Still's washes; since pass 25 one of its drops a word's);
the mark test writes
`mark-M3-1x.png` and `mark-M3-2x.png` (16 and 32 px, black on clear). `app/build/` and `app/renders/` are
git-ignored.

## Layout

- `Sources/LemnaCore` (no AppKit): `Text.swift` the model (one string with `"\n"` between paragraphs, U+2028 for a
  line break inside one, and a caret in Characters; each key's edits and motion as a `Change`; a journal edit applied,
  the replay; the line's two parts around the caret with ` ¶ ` and ` ↵ `; since pass 30 a paste's text and ⌘Z's way
  back to a text as ordinary edits), `History.swift` (pass 30) the undo stack and its groups, `Line.swift` the geometry and drawing (Core Text shaping around the caret, the two
  fades, the clips at the caret, caret, the band, the newest glyphs' look, the colours), `Glide.swift` the glide, the curve
  (`Curve.easeOutQuint`) and the newest glyphs' entrance (`Entrance`), `Effects.swift` the Effects submenu's choice and
  every effect's magnitude (`Effects.Tuning`), `Ambience.swift` the ambience's choice (the Settings window's since pass 39), every magnitude of the
  ambience (`Ambience.Tuning`), what the line sends and a scene is told, the stage, the sprite, the atlas's index and the
  run of a scene (`Ambience.Run`), `Scenes.swift` the four scenes, `Particles.swift` the Metal pipeline that draws them
  (`Ambience.Renderer`: the shader's source, the glyph atlas, an offscreen frame for the tests), `Keyboard.swift` where
  each physical key is on a MacBook's main block, ANSI and ISO (pass 16),
  `Mechanical.swift`
  the deterministic pass R1, `Session.swift` the end of a session as a state machine, `Summoning.swift` the menu-bar
  mark, when the Bluetooth notice shows and since pass 20 Start at Login's title and tick (`LoginItem`), `Sound.swift` the Sound submenu's packs and what ⌘K does (`SoundChoice`), since pass 23 its beds and when the bed plays (`BedChoice`), `Theme.swift` (pass 21) the themes, one literal each (`Theme`: palettes for day and night, type, box, motion, the preset's defaults; `Theme.all`), `Box.swift` the box's frame on a screen (`BoxFrame`), which container
  holds the line (`Surface`) and when a click outside or, since pass 26, another app in front hides the box
  (`ClickOutside`), `Paste.swift` the paste's
  decision table, and since pass 17a its steps in order (`Paste.acts`) and the wait for Return to come up
  (`ReturnUp`), `Handoff.swift` (pass 17b) the hand-off's motion: the line cut into its glyphs, when each sets off
  and where it is, the box's collapse, the dim's lift, and when it plays; `Chord.swift` (pass 36) the summon chord:
  its glyphs, how `hotkey` keeps it, the rules and the checks against Lemna's keys and the system's, what the menu
  and the Settings window say (`Chord`, `MenuKey`); `Shortcuts.swift` (pass 37) the box's fixed chords as the
  Settings window lists them (`Shortcuts.overview`).
- `Sources/Lemna`: `main.swift` the app, window, menus, clicks and the sound toggle, the Effects submenu, Start at Login, summoning and the two containers
  (`apply()`), a click outside the box, and the end of a session (Done's paste or copy, Copy, Save, Discard, each
  finishing at once); `Box.swift` the box (the non-activating panel, the dim overlays, the line in it; since pass 14 its
  face and its still border, its open and close, the last look that fades (the sheen and the warming border until
  pass 18); since pass 17b the hand-off's glyph layers, the collapse, and the ghost carrying them on); `Paste.swift`
  the pasteboard (Copy's item; since pass 11 nothing is read from it), the posted ⌘V and since pass 17a the hand-off's
  timing log (`Timing`); `Keeper.swift` the journal in
  the app (open and restore, append, the flushes); `LineView.swift` the view (text input, the keys of B4, edits as
  journal edits and clicks, the two glides, display link; since pass 15 each key handed on to the ambience after its
  frame; since pass 17b the hand-off's cut of its last frame); `Ambient.swift` the ambience on each dim (the scene
  thread, the Metal layer and its display link);
  `Sources/LemnaCatch` one Objective-C function that catches an Objective-C exception, which Swift cannot (the display
  link's callback runs inside it);
  `Strip.swift` the Metal band (Core Graphics into a shared
  buffer, blitted into the drawable); `Frame.swift` the surface's bottom edge (the Bluetooth notice, a hand-off's
  note); `Summon.swift` the hotkey (Carbon; since pass 36 the kept chord, registered again on a change and paused
  while the field listens, and the readers of the system's chords, Lemna's menu keys and the layout's letters) and the
  menu-bar item with Lemna's menu; `Settings.swift` (pass 36) the Settings window and the chord's field (`Recorder`).
- `Tests/LemnaCoreTests`: the model, the glide, the fades, nothing before the caret drawn right of it, the text after it
  from the caret to 95 %, the renders (`CoreTests`, `RenderTests`); every key of B4, its boundaries, the word rules,
  Characters with é, 🙂 and 👩‍💻, the replay of every key's edits, since pass 30 a paste's text and ⌘Z's groups
  (`EditingTests`); R1's rules, counts and idempotence (`MechanicalTests`); the state machine (`SessionTests`); the
  journal round trip through the app's replay, edits in the middle included (`JournalReplayTests`); the menu-bar mark,
  the Bluetooth notice, the muted colour's contrast, Start at Login per status (`FrameTests`); the box's frame and its clamps, one container at a
  time, the paste's decision table, the click-outside guard's table (`BoxTests`); the Sound submenu's default, a
  pack's choice and ⌘K, since pass 23 the bed's default, choice and when it plays (`SoundTests`); the Effects submenu's defaults, Off, Reduce Motion and its round trip through a
  dictionary, the entrance on the curve, the newest glyph's fade, the old keys read, every duration on the scale
  (`EffectsTests`); the Ambience submenu's
  default, round trip and Reduce Motion, the tuning, the sprite's layout, the stage, the typing rate, a run's 4 s and its
  close, the glyph that leaves the box's edge, each mode's coupling, the cap, the shader and one frame offscreen, the
  renders (`AmbienceTests`); since pass 15b the display link's lifecycle: a real layer driven by a link refuses
  `nextDrawable`, Esc during typing and during the close's and the dim's fades in every mode and Off, a hand-off, a
  close at once, a new show, the end 4 s after the last key, the Esc sequence on a real layer and link
  (`AmbienceLinkTests`); since pass 16 the keymap (`KeyboardTests`) and where each mode's sprites start for a key;
  since pass 17a the paste's steps and the wait for Return (`PasteTests`); since pass 17b the hand-off's cut, its
  schedule for a paste and a copy, the collapse and the lift, when it plays, and its renders (`HandoffTests`); since
  pass 21 the themes: Lemna equal to the literals it replaced, the packs and modes named, the contrast per appearance,
  the palette by appearance, the font and the atlas's, the preset, Still's fades (`ThemeTests`), and Rain on Still's
  day wash (`AmbienceTests`); since pass 36 the summon chord's glyphs, its storage, the rules, Lemna's own keys and the
  system's, and what the menu and the window say, since pass 37 the overview's chords (`ChordTests`).

## What it covers

Milestone 1, the surface (the window is window mode since pass 6, below):

- One ordinary resizable window (titled, transparent title bar, standard buttons, minimum 600 × 300, frame
  remembered), so tiling window managers place it; full screen from the green button (⌃⌘F is Open Window since pass
  6). No Edit menu yet.
- The line: Menlo 28 pt, its end at a caret fixed at 60 % of the width, vertically centred; the whole line glides left
  by each key's advance over 140 ms (ease-out cubic, a leftover capped at one advance; easeOutQuint since pass 14), and back on backspace; nothing
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
  that deletes clicks `.backspace`; caret moves are silent. Since pass 19a ⌘⏎'s paste plays `.send`, below.)
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
  the whole panel at alpha 0.97 (on the background alone, the opaque Metal band would show as a darker stripe). (Since
  pass 14: `#1a1b26`, opaque, a 1 pt accent border, opening and closing with a fade; below.) Size
  (`BoxFrame`): 60 % of the visible frame of the screen with the pointer (at least 600 pt, at most the screen), 4 em
  tall (112 pt at 28 pt: the line's 2 em band with one em above and below), centred across, its centre two thirds of
  the way down, on whole points, inside the visible frame. A box dragged elsewhere goes back to that place at the next
  summon.
- The dim: one borderless window per screen, black at 0.35, transparent to the mouse, one level under the box, the
  box's collection behaviour, on and off with the box at once; fitted to the screens at each summon. The menu bar and
  the Dock stay above it. (Since pass 14 the box's background at 0.5, fading with the box.)
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

Pass 14, the effects (DESIGN.md F1, amending F0, W2, S1's curve and G1 H1, 2026-10-28; pass 14b, below, changed
the colours back and raised the magnitudes):

- Colours (T1, `Style`): Tokyo Night's roles as the maintainer's other apps use them, in the box and the window: background
  #1a1b26, text #c0caf5 (10.6:1), muted #7f88b2 (4.9:1; under Increase Contrast #a9b1d6, 8.1:1), caret #7aa2f7
  (`Style.accent`, 6.8:1), line #3b4261 (`Style.line`). The bottom edge's text takes the muted grey as before.
- The box (`Box.swift`): opaque always (Q1; no Reduce Transparency case, nothing read for it). The panel's content is
  the background with its 10 pt corners and the line; over the line a `Face`, a layer-hosting view of Lemna's own
  that lets clicks through, holds the border (B1: 1 pt, `#7aa2f7`, on the box's whole points, so sharp at 1× and
  2×) and above it the sheen, so the word sheen can light the border.
- The dim (D1): per screen as before, a layer-hosting view whose layer is the box's background at opacity 0.5.
- Open (P1): from off screen the panel's alpha goes from 0 to 1 (`NSAnimationContext` and `animator()`, so the
  system shadow fades with it) and the content layer's transform from 95 % about its middle to identity
  (`CABasicAnimation`), both 250 ms on `quint` (`CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)`); the dim's
  layers fade to 0.5 alike. The panel is key and the line draws from the first instant; once grown, the shadow is
  taken again (`invalidateShadow`).
- Close (P1): `Box.hide(_:)` takes the panel off screen at once, so the keys (and a paste's ⌘V, 120 ms on) go to the
  app behind as before. Its last look goes into a second borderless panel (`ghost`: never key, ignores the mouse,
  the same level, its own shadow): the strip's last frame (`Strip.lastFrame`, `LineView.snapshot`) in place under a
  `Face` with the border's colour as it showed; that panel's alpha fades to 0 over 160 ms on `quint`, then it goes,
  and the dim fades with it. At a hand-off (`.handOff`: the paste, Copy, Save…) the sheen crosses it first: 300 ms,
  the fade starting at 140 ms so both end together. Open Window (`.atOnce`) and Reduce Motion, or Pop unticked, go at
  once. A summon during the fade removes the last look at once. `turn` moves on at each show and hide, so a late
  fade's end or a cooling does nothing.
- The glide (G1): `Curve.easeOutQuint`, the bezier's x solved for the time (Newton, then bisection), in `Glide`; the
  same 140 ms; Reduce Motion jumps as before. `Line.ease` (the cubic) is gone.
- Glyph pop-in (K1) and paragraph fade (E2): `LineView` keeps one `Entrance` (the UTF-16 units the key added before
  the caret, its time, whether it grows): typing starts one that grows (K1), Return one for the ` ¶ ` that only fades
  (E2), anything else (a delete, a move, a dead key's mark) ends it, and the next key replaces it (the glyph before
  drawn whole). `Line.draw` takes `Newest` (units, alpha, scale): each glyph's alpha gets one more factor, and the
  newest few are drawn scaled about their baseline-left in the same pass (`Glyph.index`, `Shaped.split` tell which).
  The display link runs while an entrance does, as while a glide does.
- The sheens (E1, K3, `Face.sweep`): a `CAGradientLayer` as wide as the box is tall (clear, white, clear), leaning
  45° (`m21 = 1`), moved by `position.x` from left of the box to right of it in 300 ms at an even pace, clipped to the
  rounded box; peak α 0.14 across the box (E1), or masked to the border's 1 pt band at peak α 0.35 (K3, on Space or
  a no-break space, not on Return). E1 on a box that stays (⌘⏎ copied instead, with its note) crosses it in place.
- Border warms (B2, `Box.keyShown`): after each key's frame (`LineView.onShown`), the border is warm; the first key
  after it cooled animates the accent back in 150 ms on `quint`; one timer per pause looks 0.5 s after the last key
  and cools the border evenly to `Style.line` over 1.5 s. Turning it off while cooled warms the border at once.
- Session › Effects ▸ (`effectsMenu`, in the main menu and the menu-bar item's menu): Pop, Border warms, Glyph pop-in,
  Word sheen, Hand-off sheen, Paragraph fade (check items, tags = `Effects.Item.allCases`), then Off (no key).
  `Effects` (LemnaCore): the ticks and Off; `plays(_:reduceMotion:)`, `available` (Reduce Motion greys Pop, Glyph
  pop-in and the sheens), `duration` (0 when it does not play), `choose` (while Off: back on with the item ticked),
  `toggle`; kept in UserDefaults as `effects`, a dictionary of the item names and `on`. The menu reads Reduce Motion
  as it opens; the line and the box read it at each key, show and hide.
- Measured: the band's draw beside the old loop (release, the box's band 905 × 56 pt at 2×, a 200-glyph line, best
  of five 2,000 frames): 41.0–41.6 µs per frame before, 40.9–41.4 µs during a pop-in, 42.5 µs during the ` ¶ `'s
  fade. The latency budget (key → presented p50/p90 no worse than the spike's 42/60 ms) was not measured: nothing was
  launched.
- Build: the executable is 0.90 MB (896,288 bytes; 803,504 before), no `/Users/` path in it; signed with "Lemna
  Dev", which `make-app.sh` now finds. The first signing with that key waited on macOS's question whether codesign may
  use it; once answered, builds sign without asking.

Pass 14b, the effects plain to see and the colours back (DESIGN.md F1 amended, 2026-10-28; the user, having tried
pass 14 with every effect ticked: "Where are the new animations, I can barely see anything." and "I liked the color
better before."):

- `Effects.Tuning` (LemnaCore, `Effects.swift`) holds every magnitude, pass 14's beside each as "subtle": Pop opens in
  0.300 s from 0.87 (subtle 0.250 s from 0.95) and closes in 0.200 s (0.160); the dim 0.5 (unchanged); the glyph
  pop-in 0.160 s from 0.70 with a 3 pt rise from below the baseline (0.120 s from 0.95, no rise); the paragraph fade
  0.200 s (0.120); the hand-off sheen 0.350 s at peak 0.35 (0.300 s, 0.14); the word sheen 0.300 s at peak 0.7
  (0.35); Border warms 0.150 s warm-up, 0.5 s quiet, 1.0 s even cool (1.5 s), `warm` the accent, `cooled` the line.
  `Box` and `Entrance` read it; nothing else holds a magnitude.
- `Entrance.glyph(units:at:)` (K1) and `Entrance.paragraph(units:at:)` (E2) replace `Entrance(units:at:grows:)`; an
  entrance carries its duration, start scale and rise. `Newest` gains `dy`, the newest glyphs' shift off the baseline
  (−3 pt at the key, 0 at rest), drawn in the same translate as the scale.
- The colours are T2 again (`Style`): background #0e1013, text #d8dce3, muted #5c646f (#8d95a0 under Increase
  Contrast), caret and `Style.accent` #7aa7f0, `Style.line` #262b32 (B2's cooled border, the old hairline). The box
  stays opaque, with the accent border; the dim is #0e1013 at 0.5.
- Tests: `theTuningIsPlainToSee`, the entrance at 70 %, 3 pt and 160 ms, the newest glyph's scale and rise in pixels
  (6 rows lower at 2×), the contrast and the renders' background and caret pixels in T2's colours; 58 in all.
- Measured: the band's draw (release, the box's band at 2×, best of five 2,000 frames, three runs): 41.5–41.8 µs for
  the old loop, 41.5–42.2 at rest, 41.7–42.1 during a pop-in, 43.3–43.5 during the ` ¶ `'s fade.
- Build: the executable is 0.91 MB (907,200 bytes; 896,288 in pass 14), signed with "Lemna Dev".

Pass 15, the ambience (DESIGN.md A1 amending F0, Plan item 12, 2026-10-28; the picks `M1+M2+M3+M4+M5+M6+M7 D0 R1 S1
C1 I1` of `docs/design-panel-lemna-ambience.html`):

- Session › Ambience ▸ (`ambienceMenu`, in the main menu and the menu-bar item's menu, after Effects): Drift, Rain,
  Rings, Beams, Grid, Fireworks, Swarm (tags = `Ambience.Mode.allCases`), then Off (tag −1), radio ticks, no key.
  `Ambience` (LemnaCore): the mode or Off (the default), `playing(reduceMotion:)` (none under Reduce Motion),
  `available` (Reduce Motion greys the modes; Off stays), kept in UserDefaults as `ambience` (the mode's raw value or
  `off`). The menu reads Reduce Motion as it opens, the box at each show and at a change in the submenu.
- The key path (`LineView`): after a key's frame (after `onShown`), `onAmbient` gets an `Ambience.Key`: the key's time,
  its kind (a glyph, Space, Return, ⌫ for every delete key that deleted), the line as shaped (`Shaped`, a reference to
  its glyphs) and how far the edit moved the text before the caret. The box hands it to each playing screen's
  `Ambient.key`: a lock (`OSAllocatedUnfairLock`) and an append; the first key after a pause also wakes the scene
  thread. Caret moves and dead keys send nothing. Nothing else changes on the line: its display link, its band, its
  draw. Window mode (⌃⌘F) has no dim, so no ambience: `Box.ambientKey` drops the keys while the box is not up.
- The layers (`Ambient.swift`): each dim window's content is now a root layer with the shade and, once a mode has played
  on that screen, a clear `CAMetalLayer` over it (bgra8, sRGB, not opaque), the screen's size at its scale. Its
  `CAMetalDisplayLink` (macOS 14) runs at 60 Hz on one `SceneThread` (a `Thread` with its own run loop) from the first
  key until the run is over (`Ambience.Run.frame` returns nil: 4 s after the last key, or at the end of a close), then
  pauses; the layer's drawable is then 1 × 1 px and cleared, so the screen-sized drawables go (pass 15b changed how,
  below). At each show `begin`
  hands it the mode (none on a screen without the box for the box-bound modes) and the stage (`Ambience.Stage`: the
  screen's size, the box and the line's band, baseline and caret in the screen's points); a new show or mode starts a
  new scene at the next key. At the box's close each scene fades out over the dim's wait and fade (`close`), and
  stops when the dim is gone (`stop`).
- The run (`Ambience.Run`, on the scene thread): the keys become the scene's events, with what left the box's edge
  found from each key's push (the glyphs before the caret whose middle passed the band's left edge, from the line's own
  font, not the paragraph marks); the typing rate (`Ambience.Typing`: the keys of the last 2 s); the alpha every sprite
  is drawn at (1, then the last second before 4 s after the last key, times a close's fade). The scene steps once a
  frame (`Ambience.Scene.step(dt:events:rate:into:)`) and appends `Sprite`s (32 bytes: centre, size, rotation, alpha,
  colour, kind and parameter); a scene spawns nothing that would take it past 2,000 (`Tuning.cap`), and the run cuts
  at it too.
- The scenes (`Scenes.swift`), each with its coupling and magnitudes in `Ambience.Tuning` (DESIGN.md A1 lists them):
  Drift, Rain, Rings (the box's outline grown by r: four sides as thin rectangles, four corners as quarter rings of
  radius 10 + r), Beams, Grid, Fireworks, Swarm. Seeded (`Ambience.Random`, SplitMix64), so the tests step them the
  same way each time.
- The renderer (`Particles.swift`, `Ambience.Renderer`): one pipeline, instanced quads as a triangle strip of four
  corners per sprite, shapes a pixel larger for their soft edge; the fragment shader covers each by its kind (an atlas
  glyph, a rectangle, a disc, a circle's stroke, a quarter ring, a beam rising to a white head) and writes premultiplied
  colour; the colours add, the alpha lays over. The atlas: the line's font at 2×, 16 cells a row, ASCII, Latin-1's
  letters and the common German and English punctuation, white on black in an 8-bit texture with two mipmap levels.
  **The shader is a Swift string compiled at runtime** (`device.makeLibrary(source:)`): the Command Line Tools have no
  Metal compiler, and the system's compiles it. Once per device and pixel format, cached in the process; the app makes
  the renderer on the scene thread at the first show with a mode, so the first key finds it compiled. No device or a
  failed compile: one line in the system log, and no ambience.
- Measured (release, this Mac, the box's screen at 2×, scratch timing): a scene's step at the cap 24 µs a frame for
  Drift (2,000 glyphs), 17 for Rings, 10 for Beams, 9 for Rain (2,000 cells), 6.5 for Swarm, 1.6 for Grid; a run with
  a key a frame 7 µs; encode, copy and commit of 2,000 sprites 11 µs; the GPU 0.39 ms a frame for 2,000 glyph sprites
  over a 3024 × 1964 drawable. The shader: 53–361 ms uncached (the first compile in a process the slowest), 1–2 ms
  when the system's shader cache has it.
- Build: the executable is 1.20 MB (1,202,384 bytes; 907,200 in pass 14b), no `/Users/` path in it; signed with
  "Lemna Dev".

Pass 15b, the crash at Esc (DESIGN.md A1's R1 amended, 2026-10-28; the user: "When I hit escape while editing it kills
Lemna"):

- Cause (the system log at the three crashes): `CAMetalLayerInvalidOperation: -nextDrawable should not be called when
  using CAMetalDisplayLink.` At a scene's end pass 15's `Ambient.halt` shrank the layer and asked it for a drawable to
  clear, from the link's callback; Core Animation refuses `nextDrawable` on a layer a CAMetalDisplayLink drives (paused
  or not, on any thread, with or without a window: a probe, and now a test), the exception crossed the callback, and
  `SceneThread`'s run loop aborted Lemna. Every scene's end went that way: Esc ended it with the close's fade, 4 s of
  silence by itself. Off, or a mode with nothing typed since the summon, never reached it.
- `Ambience.Lifecycle` (LemnaCore) decides what each frame does (`Step`: the sprites at an alpha, or a cleared frame;
  the drawable's next size; the layer's show; the pause): a new scene's first frame is cleared and at the screen's size,
  the layer is shown from its second; when nothing plays, a cleared frame, the drawable parked at 1 × 1 px once it is
  committed, a second cleared frame, the pause; `stop` (the dim gone) ends a scene, and the next frame, if one comes,
  parks. Free of Metal, so the tests drive whole sequences.
- `Ambient` (the app) only carries the steps out, on the scene thread: each frame drawn into `update.drawable`, the
  drawable's size set after the commit, the pause, and a show handed to the main thread, which owns the layer's
  geometry and opacity: the box fades the layer out with the shade at a close (`undim`), and the show (only for the
  turn still open) brings it back. `close` ends the scene `Tuning.closeAhead` (50 ms) before the dim goes, so it clears
  and pauses while the window is still up. Nothing calls `nextDrawable` any more.
- The callback's body runs inside `LemnaCatch` (`Sources/LemnaCatch`, a C-family target with one function, `@try` and
  `@catch` around a block): an Objective-C exception that Core Animation or Metal raises there again is logged
  (`Lemna: the ambience stopped: …`), the link is paused and invalidated on the scene thread, its callbacks ignored, the
  keys dropped and the layer hidden; Lemna goes on without ambience until the next launch.

Pass 16, the ambience plain to see and where the key is (DESIGN.md A1 amended, 2026-10-28; the user: "The ambience
effects are way too subtle and some of them could also be more reactive depending on where the key is on the
keyboard."):

- `Ambience.Tuning`: about two to three times pass 15's alphas, larger where that reads better, a little longer where
  the fade took them early, pass 15's values beside each as "subtle" (DESIGN.md A1 lists them).
- `Keyboard` (LemnaCore): a virtual key code (kVK_…, NSEvent's keyCode: the physical key, the same whatever the
  layout) to its place on a MacBook's main block: the middle of its row (0 the number row to 4 the space bar's) and
  column (0 to 15 key units), its width and height; `rows` and `columns` the cells of a 5 × 15 grid it covers. ANSI's
  table and ISO's differences: kVK_ISO_Section left of 1, kVK_ANSI_Grave the extra key left of Z, kVK_ANSI_Backslash
  left of Return in row 2, the tall Return over rows 1 and 2, a short left Shift. The arrows, Esc, the function row,
  the keypad and JIS's own keys have no place. `Keyboard.kind(layoutType:)` reads KBGetLayoutType's answer.
- The key path: `LineView.ambient` adds `NSApp.currentEvent`'s keyCode to the key it hands on (none when no key
  event brought it, the accent menu's pick); `Ambience.Run.take` finds its place on the scene thread for the stage's
  keyboard (`Stage.keyboard`, set at each show from `physicalLayout()`: KBGetLayoutType of LMGetKbdType, looked up
  with `dlsym` since the SDK has no header for it; ANSI when it is missing); the events carry it
  (`Ambience.Event.typed(slot:at:)`, `.space(_:)`, `.paragraph(_:)`, `.backspace(_:)`). `Stage.screenX` and `boxX`
  turn it into an x across the screen (`Tuning.screenSpan`) or along the box (`boxSpan`, the caret's x without one).
- The scenes: Rain's column at the key across the screen, anywhere within the key's width, starting higher the higher
  its row (`rainRows`); Rings' circles centred on the box's top edge where the key is, out past the screen's farthest
  corner, each drawn as 8 to 96 arcs of about 100 pt (`circle`, the `bend` sprite: the shader curves a thin quad
  about a centre the radius below it and cuts it square at its ends, so the arcs meet without overlapping); the
  rounded outline of pass 15 and its quarter rings (`arc`) are gone; Grid's keyboard of 5 × 15 cells, centred under
  the box a cell below it (over it if the screen has no room), its cells' ages in a fixed table, the near cells for a
  key without a place as before; Fireworks' rocket and Swarm's bubbles at the key along the box; Beams at the key's
  row (`beamRows`), Space along the bottom of the box's screen, Return across every screen.
- Measured (release, 2×, scratch timing): a scene's step at the cap 26 µs a frame for Drift, 10 for Beams and Rain, 11
  for Rings (now circles of arcs), 7 for Swarm, 3 for Fireworks, 1.6 for Grid; encode, copy and commit 9–12 µs; the
  GPU 0.39–0.58 ms for 2,000 glyph sprites at the line's size over a 3024 × 1964 drawable, 0.13 ms for 20 rings of
  300–1,060 pt (446 arcs).

Pass 17a, the paste's lost second (DESIGN.md O1+O2+O3 and E2 amended, F1's E1; 2026-10-29; the user: "there is
almost a second of delay when hitting cmd+enter to paste the text until the text is actually pasted. This is probably
a delay we can't get around"):

- Where the time went, from the code and measured where that needs no launch: the wait for Return to come up ran its
  whole 1 s cap whenever ⌘ was still down as Return came up, the usual way to let go of ⌘⏎. `-[NSApplication
  sendEvent:]` gives a key-up with ⌘ down to no window, so `BoxPanel.sendEvent`'s key-up hook never fired (GLFW's
  Cocoa backend forwards such key-ups from a local monitor for the same reason; a probe here: a local monitor sees a
  ⌘ key-up sent through `NSApp.sendEvent`). The key-down itself was right: ⌘⏎ reaches Done as the main menu's key
  equivalent (AppKit's dispatch or the box's `sendEvent`), with `NSApp.currentEvent` the key-down either way, so the
  wait began; only its end never came. Next, before the box went, the session's finish: the key deleted from the login
  keychain, the file deleted, the next session's key added and its file made, 30 ms median and 89 ms at most over 15
  runs (the delete 12 ms, the add 13; with a full flush queued just before, as Done queues one; a scratch keychain
  service, cleaned up). Then the 120 ms settle. R1 (0.25 ms for 2,500 characters), the pasteboard (0.3 ms) and
  `bringForward` (nothing to do while the app is in front) cost nothing. ⌘⏎ → ⌘V was about 1,000 + 30 + 120 ms, some
  1.15 s, and the hold of Return plus about 155 ms when ⌘ came up first.
- The wait (`afterReturnIsUp`; `ReturnUp` in LemnaCore): a local key-up monitor, which sees each event before AppKit
  drops it, and the key's own state (`CGEventSource.keyState`, `.combinedSessionState`, Return and Enter), read at once
  and every 50 ms in case the key-up goes elsewhere; whichever comes first. A key held down keeps the box at most 1 s,
  as before (auto-repeat starts at the delay until repeat, 0.5 s on this Mac, and its repeats reach the box, where Done
  is off). `BoxPanel.onKeyUp` is gone.
- The order (`Paste.acts`, carried out by `App.run`): the pasteboard and the session handed off, the box gone, the app
  brought forward only when it is not in front, the settle (`Paste.settleInFront`, 30 ms, when it was in front all
  along, the usual case: the window server moves the keys back and a password field there turns Secure Input on
  again; `Paste.settle`, 120 ms as before, when it had to be brought forward), Secure Input read again, ⌘V, and then
  the session finished in the same turn. Copy and Save… let the box go first and finish after it (`leave`); a copy
  with a note finishes first as before, since its box stays.
- The box's last look is now the text as it was handed off: until now the finish cleared the line and drew the empty
  line before the box went, so the hand-off sheen (E1) crossed an empty line.
- The timing log (`Timing`, the app's `Paste.swift`): off unless `defaults write dev.lemna.app LemnaTiming -bool true`
  (read at each Done and Copy); one line per step, `Lemna timing: <step> at <ms> ms`, counted from the key-down's own
  timestamp: `Done` (or `Copy`), `R1 applied`, `Return up (keyUp | released | cap)`, `target in front` (or `not in
  front`, then `activation requested` and `target active`), `clipboard written`, `box hidden`, `⌘V posted` (or `Secure
  Input on: copied instead`), `session finished`. `log stream --predicate 'process == "Lemna"'` in a terminal, or
  `log show --last 2m --predicate 'process == "Lemna"'` after; `defaults delete dev.lemna.app LemnaTiming` turns it off.
- Expected now: ⌘V about 35 ms after Return comes up, so the hold of Return (about 100 ms for a tap) plus 35 ms from
  the key-down; Copy's box goes as Return comes up.

Pass 17b, the hand-off's motion (DESIGN.md F1's E1 replaced by H1 A0 T1 C1, F0, W2, S1, O1+O2+O3 amended; 2026-10-29;
the user: "Right now the animation that is used is really lackluster and not well done. This can be improved a lot.",
then the picks `H1 A0 T1 C1` of `docs/design-panel-lemna-handoff.html`, H1 on easeOutQuint):

- The schedule (`Handoff`, LemnaCore): `pieces` cuts the line as `Line.draw` showed it into one `Piece` per glyph with
  some alpha (its cell: the glyph's advance where the band showed it, clipped at the caret, the band's edge or 95 %,
  and the font's ascent and descent and 0.1 em, on whole pixels), ranked by how many glyphs stand between it and the
  caret; `Piece.start` is 7 ms a rank up to 120 ms (`exitStagger`, `exitStaggerCap`), and 0 for the text after the
  caret on a send (it is ahead); `reach` is the box's width for a send, 1.25 times its height for a rise (`sendReach`,
  `riseReach`); `offset` runs a piece over it on `Curve.easeOutQuint` in 200 ms (`exit`); `box(at:)` the collapse from
  120 ms to 0.9 and transparent over 160 ms (`collapseAt`, `collapse`, `collapseScale`), `dim(at:)` the lift over
  160 ms (`lift`), `end` 280 ms; `leaving` says whether a hand-off moves (Effects ▸ Hand-off), fades as Esc (Pop) or
  goes at once (Reduce Motion, Off).
- The cut (`LineView.cut`): the strip's last frame (`Strip.lastFrame`), the offsets that frame drew the line at, the
  band's place in the box and the scale; the strip hidden, its caret with it, until the line is loaded (the session
  finished) or resumed (the hand-off did not happen); no frame is drawn into it meanwhile.
- The motion (`Box.handOff`, from `done`, `copyText` and the save panel's completion, before the wait for Return): in
  one transaction, the strip hidden and one `CALayer` per piece in the face (`Face.send`: under the border, clipped by
  the content's rounded corners), its contents the piece's crop of the last frame (`CGImage.cropping`, no copy), its
  `position.x` (send) or `position.y` (rise) animated by `reach` over 200 ms on `quint`, `beginTime` the key's time plus
  its start, `fillMode` backwards; the box's shadow off; the content layer's collapse (`transform` about its middle and
  `opacity`, `beginTime` 120 ms on, `fillMode` both); the dims' shades and the ambience's layers fading to 0 over
  160 ms, the scenes closing; then `CATransaction.flush()`, so the first frame goes out whatever the key's turn does
  next. A box that stays (⌘⏎ copied instead) gets the rise alone. `Timing` logs `motion started`.
- The handover (`Box.hide`, at `Paste.acts`' hide or Copy's and Save's `leave`): while a motion runs, the ghost window
  gets the same pieces and the same collapse with the same absolute times (`carryOn`), no shadow, is put in front and
  flushed, and the box goes; the ghost goes at the motion's end, the dims once the lift is over. Core Animation keeps
  the times, so nothing jumps and nothing of it runs on the main thread, which then posts the ⌘V and finishes the
  session. Hand-off off: P1's fade as before (Esc's), or at once. `unsend` puts a box back whose hand-off failed after
  its motion began (the pasteboard refused, ⌘V could not be made).
- Band vs ghost: the panel's cost line had the exit in `Line.draw` and the ghost only for the collapse, with the ghost
  as the fallback "if the panel cannot stay up without the keys, or a frame slips". Chosen: the ghost's way from the
  first frame. The band draws on the main thread, which at the paste writes the clipboard and right after the ⌘V runs
  the finish (30–90 ms), and AppKit animates a window's alpha from there too; and the strip is only the band (2 em),
  where a rise has to cross the box's top edge 27 pt above it. The first frame is still built on the key event.
- Effects ▸ Hand-off (`Effects.Item.handOff`, raw value `handOff`) replaces Hand-off sheen (`handOffSheen`, whose kept
  tick is now ignored, so it starts ticked); it moves, so Reduce Motion greys it. `Box.sweep` (E1 on a box that stays)
  and the sheen's tuning are gone; `Face.sweep` stays for the word sheen (K3).
- The ghost and the dims have `canHide` off: `handBack` hides Lemna after a question or the save panel, which until now
  took the ghost and the dims with it at once.
- Renders (`handOffRenders`): the band drawn by `Line.draw` at 2×, cut by `Handoff.pieces`, the pieces drawn at their
  offsets into the box, shrunk and faded by `Handoff.box`, over a white page with grey lines dimmed by `Handoff.dim`.
- Build: the executable is 1.36 MB (1,355,504 bytes; 1,298,960 in pass 17a), no `/Users/` path in it; signed with
  "Lemna Dev".

Pass 18, the motion revised (DESIGN.md F1 and A1 amended, Plan item 13; 2026-10-29; the user: "Use the installed
frontend-design skill to revise all the animation and remove them if they are not good or revise them."):

- Kept as they were: the box's pop open and close fade (P1), the glide (G1), the ` ¶ `'s fade (E2), the dim (D1), the
  still accent border (B1) and the hand-off (H1 C1), the one bold moment.
- The glyph fade (K1, `Effects.Item.glyphFade`, "Glyph fade"): `Entrance.glyph` fades the newest glyph in over 80 ms
  (`Tuning.glyphFade`), opacity alone; `Newest` and `Entrance` lose their scale and rise, `Line.draw` its scaled path.
  It moves nothing, so Reduce Motion leaves it on, as the paragraph fade. `Effects(kept:)` reads a missing `glyphFade`
  from the old `glyphPopIn`.
- Removed from the box: Border warms (B2) and Word sheen (K3): the face's sheen layer, gradient band and ring mask,
  `Face.borderColor`, `shownBorder`, `sweep` and `stop`, the box's cooling timer, `keyShown` and `effectsChanged`,
  `LineView.onShown`, their tuning and `Style.line`; every item now starts ticked (`byDefault` gone); a kept
  `borderWarms` or `wordSheen` is ignored.
- Removed from the ambience: Beams, Fireworks and Swarm (their scenes, their rows of `Ambience.Tuning`, `beamRows`, the
  unused `white`), and the shader's disc, small ring and beam with `Sprite.stroke`: `Sprite.Kind` is `glyph`, `rect`
  and `bend` (2 now); a kept `ambience` naming a removed mode reads as Off.
- One curve, one scale: easeOutQuint wherever a curve is used, now also a scene's fade at a close (`Run.alpha`; the
  even fade over the linger's last second stays, a decay); durations 80, 140, 200 and 300 ms, so the hand-off's `lift`
  and `collapse` are 140 ms (were 160) and `Handoff.end` 260 ms (was 280).
- Menus: Effects ▸ Pop, Glyph fade, Hand-off, Paragraph fade, Off; Ambience ▸ Drift, Rain, Rings, Grid, Off.
- Build: `make-app.sh` built the release and assembled the bundle; the executable is 1,266,632 bytes before signing
  (1.27 MB; pass 17b's 1,355,504 was signed), no `/Users/` path in it. The signing with "Lemna Dev" waited on macOS's
  keychain question (codesign asking to use the key) for 24 minutes unanswered and was stopped, so `build/Lemna.app`
  is not signed with "Lemna Dev" until `make-app.sh` runs again with the question answered.

Pass 19a, the send sound (DESIGN.md K1 amended; 2026-10-30; the user: "One additional thing is that I would like to
have a really satisfying sound when sending the text off to a app. I like the default keychron sounds, they sound well,
so something in the spirit of that. Maybe the sendoff sounds should be tied to the sound pack used.", then the picks
`S1 P1 E1` of `docs/design-panel-lemna-rain.html`):

- The new kind: `KeyKind.send` in `lib/LemnaClicks`, one `send-1.wav` in each pack's `pack.json` (a pack without it
  does not load), cut from the pack's own recordings: Keychron the Enter take with its release (290 ms), Typewriter the
  carriage's run and its stop (440 ms), Soft the FUJITSU Enter with its release (240 ms), Electric the clutch's impact
  spliced onto the end of the carriage's run (420 ms; its credit line says "spliced"). `lib/LemnaClicks/THIRD_PARTY.md`
  has the sources, licences, commands and measures; `tools/build_packs.sh` makes them. The player takes 52 samples now
  (13 a pack, 0.67 MB as files).
- When (`done`, `copyText`, `saveText`): ⌘⏎ plays `.send` once, when `Paste.decide` says paste, just before
  `box.handOff(.send)` builds the motion's first frame (the timing log's `motion started` follows it); a ⌘⏎ that
  copies instead (the `.copy` case, and the window, where it always copies), Copy ⌘⇧⏎ and Save… ⌘S (once the file is
  written) play `.paragraph`, Return's click. Sound ▸ Off: nothing. Reduce Motion and Effects off take the motion away,
  not the sound. No key-up sound (U1).
- Build: the executable is 1,278,576 bytes (1.28 MB), no `/Users/` path in it; signed with "Lemna Dev"
  (`Authority=Lemna Dev`) and verified.

## Known gaps

- Pass 19a is not tried: nothing was launched and nothing listened to. Untried: whether each pack's send sounds
  satisfying and in its pack's material, whether it lands with the motion (the release or the stop at 98–257 ms, the
  motion's end at 260 ms), whether the Typewriter's send is too quiet beside its Return (`--gain +2` is the first step,
  sendoff.md §4), and whether Electric's splice sounds made.

Pass 19b, Rain as the films' rain (DESIGN.md A1 amended; 2026-10-30; the user: "I would really like it to be even
more like the matrix rain animations. [...] I would like to have it ambient in the background (low key, but still
covering more or less the whole screen) and then it should simply get more intense when writing."; G1 I1 T1 C2 K1 W1
of `docs/design-panel-lemna-rain.html`):

- `Rain` (`Scenes.swift`): a fixed grid of square cells (`rainPitch` × the glyph's cell height at `rainScale` 0.5:
  18.5 pt at Menlo 28), the cells' glyph, lighting, trail and top alpha in flat arrays sized to the grid, the heads in
  one array reserved at the show (two a column and as many from keys), so a step allocates nothing but `out`. Each
  column keeps its share of `rainSpeed` and its travel; a head lights the cells it steps into, a cell's alpha falls
  linearly with its column's travel over the head's trail; a column starts a head at the top at the rate that keeps
  `rainActive` of the columns falling, at most two, `rainGap` behind the last one's trail; heads draw first (one a
  cell, a key's before the others), so the cap would take trail cells. The intensity follows `rate / rainFast` up with
  τ `rainRise`, down with τ `rainSettle` after `rainHold`; every magnitude is a pair (idle, typing) in
  `Ambience.Tuning`, interpolated linearly. A glyph key starts a head where pass 16 put its drop, the typed glyph at it.
  The scene steps `rainAhead` (20 s) at its birth, at rest and undrawn; `frameRate` is 30 at rest, 60 from a key.
- `Ambience.Glyphs.rainSet`: the slots of `012345789Zz:."=*+-<>|_` (K1), beside `letters`.
- `Mode.ambient` (Rain): `Run.alpha` ignores the linger, `Lifecycle.frame` makes the run at the show's first frame
  with no key (still a cleared frame before the layer shows), `Step.rate` carries the frame rate the scene wants when
  it changes; `Ambient.begin` wakes the scene thread for it as a key would, `pause` goes on while it is up, and the
  frame sets `preferredFrameRateRange` on the running link.
- Tests: 102 (94 before; the old rain test replaced by the grid, the step and the trail dimming in place, the glyph
  changes, a key's head, the ramp, the sprite count on 2560 × 1440, an ambient run, and two lifecycle sequences: born
  at the show, 30/60 Hz, the close; a new show after a close; the real-link test runs Rain too and sets its rate).
- Build: `make-app.sh` built the release and assembled the bundle; the executable is 1,276,856 bytes before signing,
  no `/Users/` path in it. The signing with "Lemna Dev" waited on macOS's keychain question and was stopped at 240 s,
  so `build/Lemna.app` is not signed until `make-app.sh` runs again with the question answered.

Pass 20, Start at Login (DESIGN.md Y1; 2026-10-30; the user: "Add a autostart option to the app"):

- The item (`Summon.swift`): Start at Login in the menu-bar item's menu, after Ambience ▸, just above Quit Lemna. Not
  in the main menu: it has no key equivalent for that menu to carry.
- `App.toggleLogin` (`main.swift`): `SMAppService.mainApp`'s `register()` or `unregister()`, or, while the status is
  `.requiresApproval`, `SMAppService.openSystemSettingsLoginItems()`; a thrown error goes to the system log
  (`Lemna: Start at Login not changed: …`), no dialog. `validateMenuItem` reads `SMAppService.mainApp.status` each
  time the menu opens and takes the title and the tick from `LoginItem` (`Summoning.swift`): not registered (or not
  found) unticked, enabled ticked, requires approval ticked as "Start at Login (approve in System Settings)". Nothing
  is kept in the defaults: the status is the setting, so a change in System Settings › General › Login Items shows at
  the next opening of the menu.
- Tests: 103 (102 before; new: `startAtLoginFollowsTheStatus` in `FrameTests`, each status's title, tick and act).
  The ServiceManagement calls have none.
- Build: `LEMNA_VERSION=0.1.1 make-app.sh`; the executable is 1,297,280 bytes, no `/Users/` path in it, linked
  against ServiceManagement; signed with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 21, the theme layer (DESIGN.md TH1, F1's T2 and T3 amended; 2026-10-31; the user: "I want to add different themes
that really change the way the app looks. [...] Keep in mind that we in the future might want to add other themes and
ambients as well.", then the picks `TH1 DC1 LK1 TY1 MO1 AM1 (rest only) BD1 CK1 RM1 OR1` of
`docs/design-panel-lemna-themes.html`; OR1's first step):

- `Theme` (LemnaCore, `Theme.swift`), one Swift literal per theme (DC1): `id`, `title`, `appearance` (`.followsSystem`,
  `.dark`, `.light`), `day` and `night` palettes (`surface`, `text`, `muted`, `mutedContrast`, `accent`, `line`, `dim`,
  `dimAlpha`, `ink`: `text`, `accent`, `blend` `.add` or `.over`, `alpha`), `type` (`face`, `bundled`, `fallback`;
  `Typeface.font` resolves it with Core Text and refuses the face Core Text gives for a missing name), `box` (`border`
  `.accent` or `.hairline`, `borderWidth`, `corner`, `shadow`), `motion` (`open` `.pop` or `.fade`, `handOff` `.stream`
  or `.fade`), `defaults` (`pack`, `bed`, `ambience`), `dark(system:)`, `Theme(kept:)`, `Theme.all` (Lemna first).
  `Theme.lemna` holds the literals that were in `Style`, `Effects.Tuning.dim`, `Ambience.Tuning.text` and `.accent`,
  `main.swift` (Menlo 28) and `Face` (1 pt, 10 pt); `Theme.still` LK1's day and night, Literata 30 with Charter 31,
  the hairline, 16 pt, no shadow, fades, and a stub preset (Soft, no bed, Rain).
- `Style(theme, dark:, increasedContrast:, font:)` (`Line.swift`): the palette resolved, `border` the accent or the
  hairline, `palette`; `Style(font:)` is Lemna's. `Style.accent` and `Style.muted(increasedContrast:)` are gone into the
  palette.
- The look follows the theme: `App.look()` reads `NSApp.effectiveAppearance` (aqua or dark aqua) and Increase Contrast,
  `restyle()` builds the style when either or the theme changed and `take(_:)` hands it to the line
  (`LineView.style`'s `didSet`: the word's width and the shape in the new font), the box (`Box.restyle`: surface,
  corners, the faces' edge, the panel's appearance and shadow, the dims' colour, the height), the bottom edge
  (`EdgeView.use`) and the window (appearance, background). `apply()` calls it as a container comes on screen, not for
  a box already up; `chooseTheme` calls it at once for the window. The box opens by the fade alone under
  `motion.open == .fade` (`pop` skips the scale); `Handoff.leaving(_:reduceMotion:handOff:)` gives a fade hand-off
  P1's close on Hand-off's tick, which `Box.hide` uses for `.handOff`; the panel's and the ghost's shadow are the
  theme's (the stream still drops it at its first frame).
- The ambience: `Stage.ink` (from the style's palette) gives the scenes their colours (`Tuning.text` and `.accent`
  gone), `Run.alpha` is scaled by `ink.alpha`; `Renderer` holds a pipeline per blend (the library compiled once per
  device; `.over` lays the colours over with one minus the source's alpha) and `encode`/`offscreen` take the blend;
  `Ambient` takes the atlas's font at each `begin` and keeps a renderer per font (`Glyphs.atlasFont(for:)`: the line's
  font when monospaced, else Menlo at its size).
- The preset (TH1): `chooseTheme` writes `theme`, the pack through `SoundChoice.preset` (the sound's on or off stays),
  `bed` (removed when nil) and the ambience (`keepAmbience`, split from `chooseAmbience`); Effects untouched.
  `themeMenu(target:)` in the main menu's Session and the menu-bar item's menu, above Sound.
- Tests: 111 (103 before; new: `lemnaIsTodaysLook`, `everyThemeNamesAPackAndAModeThatExist`,
  `everyThemeReachesItsContrastInEachAppearance` (WCAG's ratio, now `FrameTests`' file-level `ratio`),
  `theAppearancePicksStillsDayOrNight`, `eachThemesFontResolvesAndRainsAtlasStaysMonospaced`,
  `thePresetSetsThePackAndLeavesTheSoundOnOrOff`, `stillOpensAndHandsOffByFades` in `ThemeTests`, and
  `rainShowsOnStillsDayDim` in `AmbienceTests`: Rain at rest laid over Still's day wash over a white app, 2,228 pixels
  differ from the wash by 8 of 255 or more, the light of Lemna's text added none). Changed: the tuning test (Lemna's ink
  in place of the colour copy), `theColoursReachTheHIGsContrast` (the palette), the renders' dim, edge and corners from
  the style. Every render that existed is byte for byte the same as before the pass.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; the executable is 1,394,400 bytes; signed with "Lemna Dev"
  (`Authority=Lemna Dev`) and verified.

Pass 22, the Still look and its typeface (DESIGN.md TH1 amended; 2026-10-31; the user's picks `LK1 TY1 MO1` of
`docs/design-panel-lemna-themes.html`, MO1's ring left to pass 24; OR1's second step):

- **Literata bundled** (TY1): `app/Fonts/Literata/` holds `Literata[opsz,wght].ttf`, the upright variable font
  (version 3.103, opsz 7–72, wght 200–900; 955,132 bytes), and its `OFL.txt`, from `googlefonts/literata` at
  `0c2761b` (`app/THIRD_PARTY.md`: source, hashes, licence). The variable font works in Core Text as it is: the family
  `Literata`, PostScript `Literata-Regular`, and at 30 pt Core Text sets opsz to 30 by itself, the weight the default
  400; no static instance was needed. `make-app.sh` copies `app/Fonts` into `Contents/Resources/Fonts`;
  `applicationDidFinishLaunching` calls `Theme.Typeface.register(fontsIn:)` on that folder before the first `Style`:
  every `.ttf`/`.otf` under it registered for the process alone (`CTFontManagerRegisterFontsForURL`, `.process`), a
  file already registered counted as done, the ones that fail logged (`Lemna: a bundled font is not registered: …`).
  `Typeface.font` then finds Literata; missing or unregistered, Still takes Charter 31 as before.
- **How to add a bundled font for a future theme:** put the family's file(s) and its licence in a folder of their own,
  `app/Fonts/<Family>/` (OFL fonts must travel with `OFL.txt`; check the licence allows bundling: iA Writer's, for one,
  ask text editors not to); add a section to `app/THIRD_PARTY.md` (source, commit, hashes, licence); give the theme
  `Typeface(face: Face(name: "<family or PostScript name>", size: …), bundled: true, fallback: <an installed face>)`.
  Nothing else: `make-app.sh` copies the whole folder and the app registers every font file in it. The tests see it
  through `stillFont`'s registration of `app/Fonts` (ThemeTests' file-level `unregistered`); a new theme's tests resolve
  its font after touching `unregistered` the same way, so the order the tests run in does not change which face draws.
  Under a proportional face check what `research_notes/Lemna themes/architecture.md` §6 lists and what pass 22 met
  below: ligatures (split at the caret since this pass), the tail's span, the note's clearance, the weight.
- **The look against look §5 and the panel's mockups** (LK1): the box's corners are Apple's continuous curve,
  `CALayer.cornerCurve = .continuous` (QuartzCore's header: macOS 10.15) on the box's content layer, the last look's
  card and the face's border, from `Theme.Shape.continuous` (Still true; Lemna false, its circular corners as before);
  the edge stays the 1 pt tonal hairline in the palette's `line`, no shadow; the caret the 2 × 36 pt bar in the green
  accent with its ends rounded by 1 pt (`Shape.caretEnds`; `Line.draw` fills it as a rounded rectangle, Lemna's square
  as before); under Increase Contrast the day caret is #465e38 (6.3:1, LK1's value; `Palette.accentContrast`, nil
  where the accent stays: Still's night, Lemna), the muted grey as in pass 21, the hairline unchanged. Reduce
  Transparency: nothing to do (Q1's box is opaque, the wash a dim). The menu-bar mark is untouched (a template; LK1
  keeps it). The window (W2) under Still takes the paper or the near-black as its background and `.aqua` or
  `.darkAqua` as in pass 21; `editing-still-day.png` and `editing-still-night.png` are its content.
- **What the renders showed and what changed**: against a headless screenshot of the panel's LK pieces with the font
  loaded, colours, size, placement (the same baseline: Core Text's ascent and descent centred in the band is what the
  mockup's `line-height: 1` box does) and the caret matched, but (1) the text was heavier: Core Graphics smooths glyphs
  in the line's bitmap by default (darker stems), the browser draws `-webkit-font-smoothing: antialiased`; "slowly" on
  the day paper had 458,356 units of ink smoothed against the panel's 391,222 and 392,473 unsmoothed, so Still's type
  is unsmoothed (`Typeface.smoothed` false; Lemna keeps today's smoothing, its renders byte for byte); (2) Literata
  forms ligatures (fi, ff, fl, ft, Th), and with the caret between their letters `Line.shape` gave one glyph on the
  caret's left, clipped there, the second letter gone: the text after the caret is now a run of its own (an attribute,
  `LemnaAfter`), which splits a ligature at the caret and keeps kerning across it. The renders draw circular corners
  (as the mockup's CSS does); the app's are continuous.
- **The bottom edge's note** (`EdgeView`): it stays at 12 pt up, 15 pt tall, its top 27 pt up. In the box the band
  starts one em less the border up (27 pt at Menlo 28, 29 at Literata 30, 30 at Charter 31); Literata's line (ascent
  plus descent 1.49 em, Menlo's 1.16, Charter's 1.22) reaches down to 36.7 pt up, 9.7 pt over the note (Menlo 38.7,
  Charter 42.1). `theBottomEdgesNoteClearsEveryThemesLine` checks it from each theme's font metrics; the comment in
  `Frame.swift` says it in em, not for one size.
- **`Line.tail`** 300 (was 200): measured on prose, 200 characters spanned 2,635–2,800 pt in Literata 30 and
  2,575–2,740 in Charter 31 (Menlo 28: 3,371), so a window over about 7,500 pt showed the fade after the caret ending
  early; the visible 35 % of a 10,000 pt window needs about 270. 300 span 4,023 pt in Literata, 3,938 in Charter,
  5,057 in Menlo. Shaping 600 characters instead of 400 costs about 15 µs more per key in Literata (54 µs against 39
  in a scratch timing), 2 µs in Menlo.
- Tests: 118 (111 before; new in `ThemeTests`: `theBundledFontRegistersAndResolves`, `stillsCaretHasRoundedEnds`,
  `stillsTextHasThePanelsWeight`, `noLigatureSpansTheCaret`, `theBottomEdgesNoteClearsEveryThemesLine`,
  `theShapedTailCoversA10000PointWindow`, `stillInTheWindow`). Changed: `lemnaIsTodaysLook` (pass 22's fields at
  today's values), `everyThemeReachesItsContrastInEachAppearance` (the caret under Increase Contrast, 4.5:1),
  `theAppearancePicksStillsDayOrNight` (the day caret under Increase Contrast, Still's card),
  `eachThemesFontResolvesAndRainsAtlasStaysMonospaced` (Literata required, Charter as the fallback of a missing face),
  `render` takes a style; `rainShowsOnStillsDayDim` takes `stillFont` (Rain now shows on 2,187 pixels of the day wash:
  the box is 120 pt tall, was 124). Renders: `idle-still-day.png`, `idle-still-night.png` (and the two Rain ones on
  Still) in Literata; new `editing-still-day.png`, `editing-still-night.png`. Lemna's renders byte for byte as before.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; `Contents/Resources/Fonts/Literata/` holds the font and `OFL.txt`; the
  executable is 1,166,656 bytes (stripped since 50be61a), no `/Users/` path in `nm -pa` or `strings`; signed with
  "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 23, the Stone pack and the rain bed (DESIGN.md K1 amended, its D1 for steady sound only, and TH1's Still preset;
2026-10-31; the picks `CK1 BD1 TH1` of `docs/design-panel-lemna-themes.html`; OR1's third step):

- 23a, `lib/LemnaClicks` only (its README and `THIRD_PARTY.md`): the Stone pack (rock on wood, a low slit drum, a hand
  chime; levelled by loudness, the send within 3 LU of its Returns, `pitched` kinds without the ±3 %) and the bed
  engine (`Bed`, `Beds/Rain`, `ClickPlayer.bed`, `startBed(fadeIn:)`, `stopBed(fadeOut:)`, `bedVolume`).
- The packs (`Sound.swift`): `SoundChoice.packs` ends with ("Stone", "StonePack"); the player loads it at launch with
  the others.
- The bed (`Sound.swift`): `BedChoice` (`beds`: ("Rain bed", "Rain"); `folder`, nil for none; `init(kept:)`, `index`,
  `choose(_:)`, an unknown folder changing nothing) and `plays(onScreen:writing:sound:)`, true while a bed is chosen,
  the sound is on, a container is on screen and the session's phase is `.writing`. `Theme.menuTitle`: the title, and
  the bed's item in lower case when the preset turns one on ("Still (rain bed)").
- The app (`main.swift`): `bedChoice`, read from `bed` at launch; `chooseBed` (tag −1 for No bed; a bed chosen while
  the sound is off toggles it on), `keepBed` (the key, nil removing it; `loadBed`; `updateBed`), `loadBed`
  (`ClickPlayer.bed = Bed.bundled(folder)`, nil for none; a missing bed goes to the system log as `Lemna: no bed: …`),
  `updateBed` (`startBed(fadeIn: 1.5)` when `plays`, else `stopBed(fadeOut: 0.6)`), called in `apply` before the
  container shows (after the box began to hide), in `handOff` after the keys stop (Done, Copy, Save…: before ⌘⏎'s
  send), in `notHandedOff`, at the end of `end` (a `defer`), in `keepSound` (⌘K, a pack, a theme) and in `keepBed` (a
  bed, a theme). An out and an in in one turn of the main thread (a ⌘⏎ that copies and keeps the box) make no
  audible dip: the fade's target is one atomic the render thread reads per buffer. `chooseTheme` writes the bed through
  `BedChoice.choose` and `keepBed`; `themeMenu` titles the items with `menuTitle`; `soundMenu` adds a separator, the
  beds and No bed (tag −1) before Off; `validateMenuItem` ticks a bed while the sound is on, as the packs.
- `Theme.still.defaults`: `pack: "StonePack", bed: "Rain"` (the ambience stays Rain until Still water).
- `make-app.sh` copies `StonePack` with the packs and `Beds` whole.
- Tests: 114 (111 before; new: `theBedIsNoneUnlessOneWasKept`,
  `theBedPlaysOnlyWhileWritingInAContainerOnScreenWithTheSoundOn` in `SoundTests`,
  `thePresetSetsTheBedAndTheThemeSaysSo` in `ThemeTests`; changed: the packs' list,
  `everyThemeNamesAPackAndAModeThatExist` (a theme's bed is in `BedChoice.beds` and has a `bed.json` under
  `lib/LemnaClicks/Sources/LemnaClicks/Beds`), the preset's Still pack). LemnaClicks: 23 of 25 run here, the two
  audible engine tests skipped, the library unchanged since 23a.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; the executable is 1,217,472 bytes, no `/Users/` path in its symbols;
  `Contents/Resources/StonePack` and `Beds/Rain` (`bed.json`, `rain.caf`, 1,477,949 bytes); signed with "Lemna Dev"
  (`Authority=Lemna Dev`) and verified.

## Known gaps

- Pass 23 is not tried: nothing was launched and nothing listened to. Untried: the rain's level against the clicks on
  the built-in speakers and on headphones (−43 LUFS over two channels, set offline); the fades by ear (1.5 s in, 0.6 s
  out, the out against the chime's 0.9 s); the space and the send of Stone; AirPods switching to the Mac when a summon
  starts the bed (sound.md §2.6); power with the bed on (`powermetrics`). In the window the bed plays while the window
  is up, Lemna in front or not (a click into another app leaves the window, unlike the box, on screen); minimised it
  plays too. The bed fades out while Save…'s panel is up (the keys stopped: a hand-off under way). The kept bed is
  decoded at launch and held (35 MB) while the sound is on or off.

Pass 24, Still water and the removals (DESIGN.md A1 and F1 amended; 2026-10-31; the user's picks AM1 with drops at
rest only, MO1 and RM1 of `docs/design-panel-lemna-themes.html`; on the other modes: "I like the rain animation but the
other ones are not really great"):

- `Water` (`Scenes.swift`), `Mode.water` ("Still water"; `everyScreen` false, `ambient` true): drops in an array of at
  most `waterDrops` (24), each its landing point, age and three crests (speed, width, start, jittered at the drop);
  one at its birth 48 pt above the middle of the box's top edge (`waterSummon`), then Poisson at `waterRate` × the
  stage's area / 1512 × 982 pt, a Bernoulli draw a frame, placed by rejection at least `waterClear` from the box (20
  tries). It reads neither the events nor the typing rate, and its random draws do not depend on them, so keys change
  nothing (tested frame by frame). A step emits for each crest a `ring` sprite at its radius and, inside it, its trough
  at `waterTroughShare`; alpha `peak · easeOutQuint(a / waterOnset) · e^(−age / waterDecay) · √(waterNear / r)`, the
  peak by the ink's blend (`waterPeak.over` 0.27, `.add` 0.14: on screen 0.16 and 0.07 under Still's ink alphas, look
  §5.3's); none under `waterShown`; a drop goes at `waterLife`. `frameRate` 30. `Theme.still.defaults.ambience` is
  `.water`; Lemna's stays Off.
- The shape (`Particles.swift`, `Sprite.Kind.ring`, raw value 1): the quad is the circle's square out to twice the
  width beyond the radius (`Sprite.ring(x:y:radius:width:alpha:colour:)`); the fragment's coverage is
  `exp(−2u²)` for |u| < 2, u = (|p| − r) / width, r and width packed as `bend` packed them (half points, sixteenths).
  Rings that cross add through the pipeline's blend, nothing new: light added on `.add`, ink laid over on `.over`.
- MO1's ring (`Handoff.rings`, `ring`, `RingLine`, `ringAlpha`, `ringOutline`, `washUnderRing`; `Effects.Tuning.ring*`):
  `Box.handOff(.send)` under a fade theme on Hand-off's tick (not `stays`, not `.rise`, not under Reduce Motion or
  Effects Off) calls `ring()`: on the box's screen's dim window, over the shade and the ambience's layer, a holder layer
  (group opacity off) whose opacity is a 48-step keyframe envelope of `ringAlpha`, holding per line (two crests, two
  troughs) three bordered layers (`ringStrokes`) whose `bounds.size` and `cornerRadius` run evenly from the box's
  outline to where the line is at 1.2 s, each shown from its start; every visible shade and ambience layer fades to 0
  evenly over `ringLife` and the ambiences close over it. `hide(.handOff)` then fades the box's last look over P1's close
  as before but leaves the dim and the scenes to the ring, and `afterLift(from:over:)` orders the dims out and removes
  the ring at its end; `show`, `hide(.atOnce)` and `unsend` end it at once. Rounded, not a circle from the centre: the
  rounded rectangle is native to Core Animation, so it costs nothing more.
- RM1: `Drift`, `Rings`, `circle()`, `Grid` and `pace()` gone from `Scenes.swift`; from `Ambience.swift` the modes,
  their tuning, `fastRate`, `boxSpan`, `Event.leaving` and `isKey`, `Run`'s `leaving`, `Stage.baseline`, `caretPoint`
  and `boxX`, `Glyphs.sprite(baselineLeft:)`, `slot(glyph:font:)` and the glyph index behind it; from the shader the
  rectangle and the bend. Left (no mode takes them now; DESIGN A1): the linger path in `Run` and `Lifecycle`,
  `Key.line` and `pushed` (LineView still sends them), `Keyboard.Position.rows`/`columns`/`cells` (read by
  `KeyboardTests`) and `Glyphs.letters` (read by a test, as before).
- Tests: 114 (111 before; removed with the modes: Drift's, Rings', Grid's, the glyph leaving the box's edge, and the
  two lifecycle sequences of a mode that starts at a key (the next show's cleared frame, the end 4 s after the last
  key); the run's linger test is now its close alone, on Still water; the real-link test and the new-show sequence run
  every mode. New: `stillWaterDropsAtRestAtItsRateScaledToTheScreen` (235 drops in 2,000 s on 1512 × 982, 240
  expected; 578 on 2560 × 1440, 596; all 48 pt clear), `stillWaterTakesNoKeys`, `aDropsRingsRiseSoftlyThenFadeWithRadiusAndTime`,
  `stillWaterStaysUnderTheCapOnALargeScreen` (at rest at most 7 drops and 27 sprites; 141 at its 24 drops),
  `ringsThatCrossAdd` (Metal, both blends), `stillWaterShowsOnStillsDayAndNightDim` (1,699 and 1,612 pixels show at
  1×) in `AmbienceTests`; `stillsPasteSendsOneRingAndCopySaveAndReduceMotionNone`,
  `theRingLeavesTheOutlineAndTheWashLiftsWithItOver1200ms`, `stillHandOffRenders` in `HandoffTests`.
- Renders: `ambience-water-day.png` and `ambience-water-night.png` (the summon's drop 1.2 s on, two drops crossing
  beside it, one more; on Still's washes over a light and a dark app), `handoff-still-600ms.png` (MO1's ring 600 ms
  after ⌘⏎ by day, the wash at half). No longer written: `ambience-drift.png`, `ambience-rings.png`,
  `ambience-grid.png`, `ambience-grid-keyboard.png`.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; the executable is 1,145,248 bytes, no home folder in its symbols; signed
  with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 25, Code rain intensifies without speeding up, its name, and a drop per word on the water (DESIGN.md A1
amended; 2026-11-01; the user, after trying passes 19–24: "I don't think the matrix code animation gets faster in the
movie, it just gets more intense. That should be reflected in that animation. Also it's odd that it's called rain when
we actually have a rain animation as well. Also the rain drops should probably also be increasing when typing as
well."):

- `Code` (`Scenes.swift`; `Rain` until now): `speed`, each column's rows a second, drawn once at the birth as
  `mix(codeSpeed, u)` from the same draw that gave its share before, so the random sequence is unchanged; a step moves
  a column by `speed[c] · dt` and a column starts a head with probability `active · speed[c] / crossing · dt`; the
  intensity no longer touches the speed (`Tuning.codeSpeed` 8–16, was the pair `rainSpeed` 5–10 / 15–30). Everything
  else of the ramp as in pass 19b.
- The name: `Mode.code` ("Code"), raw value `code`; `Ambience(kept:)` reads `rain` as `code`; the tuning `rain*` →
  `code*` (`rainRows` → `codeRows`), `Glyphs.rainSet` → `codeSet`; the menus take the title, so Session › Ambience ▸
  and the menu-bar item's read Code, Still water, Off. `BedChoice` and its "Rain bed" untouched.
- `Water`: the events now count: `.typed` marks a word begun and keeps the key's place; `.space` and `.paragraph`
  after one drop `wordDrop(at:)` unless the last word's came less than `waterWordGap` (0.8 s) ago; `.backspace` and
  the rate nothing. `wordDrop`: x `Stage.screenX(key)` (the caret's x without a place), y from `waterTop` (40 pt)
  under the stage's top edge for row 0 to `waterClear` above the box for row 4, linear in `Keyboard.Position.down`.
  The word's drop takes its crests' random draws before the frame's rest draw, so a word moves the rest drops' dice
  but not their rate.
- Tests: 126 (124 before). New: `aColumnKeepsItsSpeedWhateverTheIntensity` (speeds in 8–16, the extremes near both
  ends; a key's head in one column row for row the same at rest and typing at 6 keys a second for 2 s),
  `stillWatersRestRateHoldsWhileWriting` (a word every 1.5 s for 2,000 s: all 1,334 words' drops at their spot, 974 at
  rest, 1,000 expected, all 48 pt clear). Replaced: `stillWaterTakesNoKeys` by
  `stillWaterDropsOneForEachWordAndNoneForAKey` (a flood of glyph keys and ⌫ changes no frame; "mo " drops at o, a word
  0.1 s later none, Spaces and Returns ending no word none, a Return after a number-row key at 40 pt under the top, the
  accent menu's pick at the caret 48 pt above the box; through a `Run` too). Changed: the ramp test asserts no speed
  and, 4 s later, more columns at the same speeds; the key head's travel at its column's speed; the grid's first-frame
  spread (15–28 columns over 20 seeds, more than 12 asserted); `stillWaterStaysUnderTheCapOnALargeScreen` adds 10
  words a second for a minute (67 words' drops, at most 17 drops, 71 sprites); the water render's drop at f 6 is now a
  word's ("o" and a Space); every `.rain` is `.code`, the Rain tests' names Code's.
- Site (`site/assets/site.js`, `index.html`, `site.css`): the Code tile's engine draws a speed per column, 8–16, and
  runs its clock at real time (was `1/3 + 2/3 I`, Rezmason's rain clock); the new heads a second take the mean speed
  12; `Water` ports `Scenes.swift`'s with the app's tuning in Lemna's ink (#d8dce3, 0.4 added, the canvas's
  `lighter`), 6 s ahead at its start, fed the burst's keys half the 7 s interval after Code; `Drift`, `Rings`, `Grid`
  and their `Runner` removed; reduced motion draws one still frame of each. Stills `assets/img/ambience-code.png`
  (the tile mid-burst) and `ambience-water.png` (its reduced-motion frame), 1080 × 608, headless Chrome.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; the executable is 1,223,088 bytes, no home folder in its symbols; signed
  with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 26, the box when another app takes the keys (DESIGN.md W2 amended; 2026-11-02; the user: "While typing the app
lost focus because another app was relaunched. I copied the text to the clipboard, which did not work and now the app is
soft-locked in a state where I cannot type, copy or paste and likely my text is gone."):

- The cause, as the code had it: the box's one way out when the keys went elsewhere was pass 7b's
  `NSWindow.didResignKeyNotification` for the panel (`boxLostKeys`). AppKit resigns a window "when deactivating or
  when another window has become key" (`resignKeyWindow`, NSWindow.h); an app that activates itself as it launches or
  relaunches does neither to Lemna, which never activated for the box. So the box stayed over the dim with its caret,
  counted key by AppKit, while the window server gave the keys to that app: the line took none, ⌘⏎ and ⌘⇧⏎ (the main
  menu's key equivalents, which `BoxPanel.sendEvent` sees only among the panel's own events) went to the other app, and
  a click into a panel AppKit counts key asks for nothing. The journal had every key (E2); the menu-bar item's Copy,
  which needs no keys, worked throughout, and by the code so did ⌃⌥Space twice (the first hid a box it read as key,
  the second brought it back with the keys).
- Another app in front: `NSWorkspace.didActivateApplicationNotification` for any app but Lemna (the window and a
  question activate it) and but the app a paste brought forward (`bringing`, set in `bringForward`, cleared when its
  activation is seen: it may come after Secure Input's note brought the box back) runs the click outside's rule with
  `lemnaHasKeys` false, whatever AppKit says of the panel (`appActivated`); the panel's resign runs it as before. When
  it holds, the box goes as with Esc (P1's fade, the dim lifting, the journal flushed, the session kept); the next
  summon shows the text and records the app then in front as the target (a relaunched app is a new process: the old
  target would have copied instead with `Copied · no app to paste into`).
- The rule (`ClickOutside.hides`, two inputs more): the box on screen, the session writing (not during a hand-off: the
  wait for Return to come up, the save panel), no question, no sheet on the box, no window of Lemna's with the keys,
  and `promptGrace` (2 s) or more since ⌘⏎ asked for macOS's Accessibility prompt (`asked`): the prompt takes the keys
  as it shows, and the box keeps its note (`Copied · allow Lemna …`) beside it; it goes when an app comes to the front
  after that, the app behind included.
- The hotkey: the box counts as having the keys while the panel is key, or a sheet on it is and Lemna is active (a
  sheet takes the keys only in the active app), so after another app came to the front ⌃⌥Space brings the box back
  rather than hiding it; a sheet on it (Save…, a question) then gets Lemna activated for it (`activateLemna`), as when
  it opened. A click into a box left up without the keys makes it key as before (AppKit's mouse-down, no activation
  for a non-activating panel).
- Tests: 127 (126 before). `clickOutsideHidesOnlyAnUnguardedBox` covers all 64 combinations of the six inputs; new,
  `anotherAppInFrontHidesTheBoxUnlessLemnaHoldsIt`: writing in the box hides; not on screen, Save…, a question,
  Return's wait and the prompt's 2 s keep it; the grace's end hides.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; the executable is 1,224,080 bytes, no home folder in its symbols; signed
  with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 27, Code as the film's title sequence (DESIGN.md A1 amended; 2026-11-02; the user, after trying Code, with two
frames of the film's titles: "Regarding the rain animation, in the movie it looks more like this: [two frames]. Revise
the animation (but do not use these colors)."):

- `Code` (`Scenes.swift`): two `Sheet`s, the main grid and a nearer one (`codeNear` 1.6 times the pitch and the
  glyphs, `codeNearBright`, `codeNearBlur`, `codeNearActive`), each with its cells in one array of `Cell` (glyph, level,
  lit, trail, top, gain, under), its columns' speeds, travel, heads and pauses (`due`, `wait`) and its column and row
  centres. A head carries its stream's gain (log-uniform in `codeGain`) into each cell it lights. A column's pause runs
  at `active · rows · pitch / codeHeight · speed / fall` a second and starts a head once it passes `wait` (drawn from
  `codeWait`): at most `most` (`codeMost` for each `codeHeight`) in the column, `codeGap` rows from its others, at the
  top or (`codeHigh`) at a row in `codeHighRows`. `Sheet.draw`: the heads first, each its halo (`Sprite.halo`, only for
  added ink) and its glyph; then one pass over the cells that changes a lit glyph and its level at `codeChange`
  (geometric skips between changes, one draw a change) and writes the cells right behind a head in the text colour at
  `codeHead · codeNeck^k` for `codeNeckCells`, the others in the accent at top · gain · level · (1 − age ÷
  trail)^`codeFade` above `cut`, through pointers into a scratch buffer of `cap` sprites, appended to the frame's in
  one call (a debug build's Array subscript, Sprite init and append cost about 100 ns each). `cut` rises 1.25 times a
  frame while more than `cap` would show and falls back 1.05 times under three quarters of it. For the tests:
  `falling`, `nearFalling`, `nearPitch`, `nearColumns`, `cut`.
- `Sprite`: a glyph's parameter is its slot in the low 12 bits and its blur in quarter mipmap levels in the 4 above
  (`Glyphs.sprite(mirrored:blur:)`; a negative width mirrors it); `Sprite.halo`, the ring of radius 0; an internal init
  from the shader's fields (`packed:shape:`).
- `Glyphs`: `kana` (U+FF66, U+FF71–U+FF9D) joins `characters`; the ones the line's font lacks come from
  `CTFontCreateForString`'s fallback in its bold (`CTFontCreateCopyWithSymbolicTraits`, `.traitBold`; LastResort
  refused), moved right by half the difference of the advances and kept only when their ink lies inside the cell the
  line's glyphs make (computed from those alone, so the cell is as before); `faces`, `face`, `shift`; `codeSet` the 22
  and the 46. `Renderer.atlas` draws each slot in its face, shifted. The shader takes a glyph's slot from the
  parameter's low 12 bits and samples it with `bias(blur ÷ 4)`.
- `Tuning`: `cap` 16,000 (2,000); Code's constants as DESIGN A1 gives them, each with its pass 25 value in its
  comment. New: `codeHeight`, `codeMost`, `codeWait`, `codeHigh`, `codeHighRows`, `codeNeck`, `codeNeckCells`,
  `codeGain`, `codeLevel`, `codeLevelSkew`, `codeFade`, `codeHalo`, `codeHaloWidth`, `codeNear`, `codeNearActive`,
  `codeNearBright`, `codeNearBlur`. Changed: `codeScale` 0.6, `codePitch` 0.5 (now the grid's own, apart from the
  glyphs' size), `codeActive` (heads a column for each `codeHeight`, was a share of the columns), `codeTrail`,
  `codeGap` (rows between two heads), `codeHead`, `codeTrailTop`, `codeChange`, `codeKeyTrailTop`, `codeKeyTrail`.
- The tuning, iterated against the frame on the renders, each step's renders looked at and the share of cells lit
  above the background by 15, 60 and 120 of 255 counted (the frame: 66, 42 and 22 %): 1, the first draft (0.8 heads a
  column, trails 24–120, the trail's top 0.3 times a level of 0.2–1, a fade to the power 1.5, head 0.6): a faint
  scatter, 46 / 10 / 7 %; 2, the top 0.45, levels 0.3–1, a linear fade, head 0.8, 1 head a column, trails 30–150: a
  curtain without streams, 78 / 27 / 9 %; 3, a gain a stream (0.35–1.6), glyphs at 0.6 on the same grid, the near
  sheet 1.6 times as bright: streams through the curtain, 76 / 29 / 13 %; 4, the top 0.55, two pale cells behind a head,
  the halo 0.22 and only where light adds, a key's trail from 0.8: 80 / 37 / 15 %; 5, a column's pause from 0.5–1.5 of
  its mean, not Poisson (13 of 81 columns had stood empty): 90 / 41 / 15 %, too even; 6, 0.8 heads a column and gains
  of 0.3–2: more contrast, 86 / 41 / 14 %; 7, heads by the column's height (2560 × 1440 had lit 64 % of its cells, the
  laptop 80 %): 85 / 37 / 11 % at rest, 95 / 74 / 42 % typing. Between 4 and 7 the debug step went from 7.8 ms to
  0.8 ms (the cells in one array read through a pointer, the glyph changes in the draw's one pass, the sprites written
  through a pointer); in release 0.02 ms.
- Tests: 134 (127 before), passing in debug and in release. New: `codeAtRestIsADimCurtainOverTheWholeScreen`,
  `severalHeadsFallInAColumnStartingAtVariousHeights`, `aStreamsGlyphsEachHaveTheirOwnBrightness`,
  `aFewNearerStreamsAreLargerSofterAndBrighter`, `aHaloLiesUnderEveryHead`,
  `aStageBeyondTheCapLosesItsDimmestCellsNotItsEdge`, `codesGlyphsDrawMirroredSoftAndInKatakana`. Changed: the tuning
  record; the stage test's code set and the katakana's face; the grid test (the main sheet, mirrored, pale heads and
  the cells behind them, trails up to the top times the largest gain); the key's head (as typed, the cells behind it,
  its trail dimming an equal step a frame between glyph changes); glyph changes counted on trail cells seen in two
  frames running (a level drawn anew can brighten a cell, so a falling alpha no longer marks one); Space, Return and ⌫
  leave the frames as no key would; the ramp's brighter heads and trails and more heads; the cap test over seven
  screens and rates, with the step's CPU time (this thread's, the best of 14 batches).
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; the executable is 1,251,680 bytes, no home folder in its symbols; signed
  with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 27b, Code builds in and lifts a little more while typing (DESIGN.md A1 amended; 2026-11-02; the user, after
trying pass 27: "Love this, this is much better. Two things, it is way less reactive (which is okay, but it could be
just a bit more. The other thing is, that it should build in, not start the animation so in your face."):

- `Code` (`Scenes.swift`): a `Head` and a `Cell` carry `veiled`; a sheet's `veiling` is true while the birth steps
  the scene ahead (`codeAhead`), so every head of then is veiled and `light` passes a head's veil into the cells it
  lights; `veiling` goes false after it. `Code.age` counts the time since the birth and `Code.veil(at:)` is the
  smoothstep of `age ÷ codeBuildIn`; `Sheet.draw(_:veil:...)` multiplies a veiled head's and halo's alpha and a
  veiled cell's by it and drops what falls under `cut` (a veiled head still marks its cell `under`). The heads born
  after the show and the keys' are never veiled. The key's halo is `codeKeyHalo`, no longer the intensity's.
- The mechanism, chosen against the code: the rest's look is the state 20 s of stepping make, with trails that
  linger 2–19 s; a cold start reaches its coverage in 4 s only with more and younger trails than it holds (brighter,
  then settling for seconds), and a fade of the whole frame brings in no streams. Veiling the stepped-ahead state and
  letting the natural births (about 16 a second on 1512 × 982 at rest) fall in at full gives streams arriving at once
  and exactly the rest's state at the end; it costs one flag a cell and a multiply while the veil is under 1.
- `Tuning`: new `codeBuildIn` 4 and `codeKeyHalo` 0.7; changed `cap` 20,000 (16,000), `codeActive` (0.8, 1.6)
  [(0.8, 1.4)], `codeTrailTop` (0.5, 0.9) [(0.55, 0.85)], `codeHalo` (0.22, 0.4) [(0.22, 0.35)], `codeChange`
  (0.5, 3) [(0.5, 2)], `codeNearActive` (0.06, 0.15) [(0.06, 0.12)], `codeKeyHead` 1 [0.95], `codeKeyTrailTop` 1
  [0.8], `codeKeyTrail` 20–60 [12–40], `codeRise` 0.15 [0.25], `codeSettle` 1.5 [1.2]; each comment gives pass 27's.
- The tuning, iterated on the renders and on the lift (the main sheet's light and its cells above 0.3, typing at 6
  keys a second against at rest, over four seeds; pass 27: 2.16 and 2.67 times): 1, the typing side raised further
  (heads 1.8, the trail's top 1.0, halo 0.45, nearer heads 0.18, the key's halo 0.5): typing's light 3 times the
  rest's and a near wall on the render, the keys' halos (0.5) hardly brighter than the others' at full intensity
  (0.45), and the 6K display's typing peak 16,010; 2, heads 1.6, the top 0.9, halo 0.4, nearer 0.15, the key's halo 0.7: 2.70 and
  3.62 times, the typed glyphs standing out, kept. The rest's light 618 against pass 27's 667.
- Measured, the build-in on 1512 × 982 over four seeds (cells drawn, light): the first frame 0 %, 0–1; 0.5 s 5–6 %,
  12–23 with 5–10 heads at full; 2 s 66–75 %, 333–407; 4 s 71–78 %, 599–672 against the rest's 72–77 %, 594–662.
  The onset of the lift: at 5 keys a second the intensity 0.39 after 1 s and 0.80 after 2 s (0.35, 0.77 before):
  mostly the 2 s of `rateWindow`.
- Tests: 137 (134 before), passing in debug and in release. New: `codeBuildsInAtTheSummon`, `aKeyDuringTheBuildInStartsItsHeadAtOnce`,
  `typingLiftsTheCurtainMoreThanInPass27`. Changed: the tuning record; the rest-state tests (grid, curtain,
  brightness, nearer sheet, halos, glyph changes, the cap's 7 s window, the stage beyond the cap, Code on Still's day
  dim) look past the build-in; the ramp's τs and hold read from `Tuning`; Code's first frame with no key no longer
  needs 100 sprites, its frame at `codeBuildIn` does. The step in release 0.02 ms at rest on 1512 × 982 and 0.09 ms
  typing on 2560 × 1440 (0.02 and 0.06 in pass 27), 0.11 ms typing on 3008 × 1692.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`; the executable is 1,252,400 bytes, no home folder in its symbols; signed
  with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 27c, the crash as typing began (2026-11-02; the user, of build 81: "We again have a bug that the app crashes when
I start typing."): on macOS 26 the main thread's update cycle also dispatches the ambience's display link
(`CA::Display::DisplayLink::dispatch_deferred_display_links`, every link with a frame deferred, whatever its run
loop), so two threads stepped one scene at once; pass 27's `scratch` came back empty and the sprites went through the
empty array's storage over the Swift runtime's allocation hook. `Ambient.metalDisplayLink` now hands a frame that
comes on another thread over to the scene thread; `Code.step` writes no more than its room holds and asserts in debug
that it is whole, `Sheet.draw` that its arrays are the grid's size. New test
`typingEveryKeyFromTheSummonKeepsCodeOnItsGrid`; 138 tests, debug and release; the executable 1,252,656 bytes, signed
with "Lemna Dev" and verified.

Pass 28, four beds beside the rain (DESIGN.md K1's BD1 amended; 2026-11-02; the user, of the eight Freesound loops of
`docs/design-panel-lemna-future-bed.html`: "FB8, FB7, FB6 (cut the low low end a bit)", then "And FB2 (cut low low end
again)"):

- The library (`lib/LemnaClicks`, its README and `THIRD_PARTY.md`): `Beds/Ship` (FB2, a spaceship's hull hum, CC0),
  `Beds/Lab` (FB6, a sci-fi lab with blips, CC BY 4.0, its credit line in `bed.json`'s `attribution`), `Beds/Space`
  (FB7, a slowed breath, CC0) and `Beds/Synth` (FB8, a synth pad's chords, CC0), each a `bed.json` and a 90 s CAF at
  −26 LUFS, made by `tools/build_beds.sh`; Ship and Lab through a second high-pass at 120 Hz (the low cut). No code
  changed there (`Bed.bundled`'s comment names the five).
- The beds (`Sound.swift`): `BedChoice.beds` is ("Rain bed", "Rain"), ("Ship bed", "Ship"), ("Lab bed", "Lab"),
  ("Space bed", "Space"), ("Synth bed", "Synth"). `soundMenu` lists them in that order before No bed, `chooseBed` takes
  the item's tag as before, `bed` keeps the folder, an unknown one reads as none; nothing else in `main.swift`
  changed. Only the chosen bed is loaded (`loadBed`, `ClickPlayer.bed`), decoded off the main thread in 30–38 ms into
  34.6 MB, so the four add nothing to the launch; the bundle grows by 5.6 MB.
- Themes unchanged: Still's preset writes Rain (its item "Still (rain bed)"), Lemna's no bed.
- The site (`site/index.html`): the facts line names five beds; the footer credits the Lab bed (CC BY 4.0, the
  author's CC BY 3.0 named too) and the three CC0 beds. The root README: the Lab bed beside the Electric pack as CC BY.
- Tests: 139 (138 before; new `theFourNewBedsFollowTheRainAndAreKeptAsItIs`: the titles and order, each folder kept
  and chosen, each `bed.json` and loop in the library, the themes' items; changed `theBedIsNoneUnlessOneWasKept`'s
  list), debug and release. LemnaClicks: 26 (25; new `theFutureBedsNameTheirLoopsAndTheirCredit`; the rain's two
  file tests now `everyBedIsANinetySecondStereoLoopWithoutASeam` and `everyBedPlaysAtTheBedLevel` over the five, the
  wrap's level held to the loop's own half-second changes instead of 1 dB), 24 run here, debug and release.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`, build 83; `Contents/Resources/Beds` holds the five; the executable
  1,252,656 bytes, no home folder in its symbols; signed with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 29, selection on the line (DESIGN.md B4 amended, TH1 noted; 2026-11-03; the user: "I want to be able to select
characters and words as well using the standard macos shortcuts (cmd+a, cmd+shift+left, shift+alt+left, ...", and
of the ` ¶ `: "the newline character, which is rendered, looks weird when having a serif font. I like the non-serif
newline character much better."):

- The model (`Text.swift`): `anchor`, the selection's fixed end (the caret its moving end; nil when none; any edit,
  `apply`, ends it); `selection`, `selectedText`, `utf16Selection`; `moveLeft`, `moveRight`, `moveWordLeft`,
  `moveWordRight`, `moveToParagraphStart`, `moveToParagraphEnd` take `extending:` (⇧), through one `go`; without it a
  selection collapses (← and → to its side and no further, the others from their side); `selectAll()` (anchor at 0,
  caret at the end); `insert` replaces a selection (its `replacing:` then unused), the four deletes take it, as ⌫
  when the caret is at its end and as ⌦ when at its start, so the motion and the journal's edits are those keys'
  (`delete(at:count:)`, then `insert(at:)` for a replacement). `Change.Motion.selected`: only the selection changed,
  the line draws again. `line(around:)`'s runs carry `selected`.
- The line (`Line.swift`): `Shaped.selected`, the selection in the line's UTF-16 units (no attribute, so no run split
  and no kerning change at the anchor); `Line.draw` puts a band behind those glyphs in each part, the caret's height,
  in the caret's colour at `Line.selectionAlpha` 0.3, as a gradient that fades as that part's text does, in the part's
  clip, under the glyphs; the caret over it. The ` ¶ `'s pilcrow in `Line.markFont` (Menlo at the line's size unless
  the line is monospaced, `Ambience.Glyphs.atlasFont`), its spaces in the line's face, in `shape` and `width` alike.
- The keys (`LineView.swift`, `main.swift`, `Box.swift`): `doCommand(by:)` takes `moveLeftAndModifySelection:` and
  `moveBackward…`, `moveRight…`/`moveForward…`, `moveWordLeft…`/`moveWordBackward…`, `moveWordRight…`/`moveWordForward…`,
  `moveToLeftEndOfLine…`/`moveToBeginningOfLine…`/`moveToBeginningOfParagraph…AndModifySelection:`, their right-hand
  and end twins, and `moveParagraphBackward/ForwardAndModifySelection:` (⌥⇧↑/↓, as ⌥↑'s two commands); `.selected`
  draws a frame. The main menu has an Edit menu (Cut ⌘X, Copy ⌘C, Select All ⌘A; no Paste) with no target, so the
  first responder gets them; `LineView` implements `selectAll(_:)`, `copy(_:)` (`Clipboard.write` of the selection)
  and `cut(_:)` (written, then ⌫'s cut with its click). `setMarkedText` over a selection takes it first;
  `selectedRange` reports it. Moves still make no click.
- Tests: 153 (139 before; 14 new: nine in EditingTests, one each in CoreTests, ThemeTests (two), RenderTests and
  JournalReplayTests), debug and release. Renders: `selection.png`, `selection-after.png`, `select-all.png`,
  `selection-still-day.png`, `selection-still-night.png`, `paragraph-still-day.png`; every Lemna render byte for byte
  as before, `editing-still-day.png` and `editing-still-night.png` changed in their ¶ only.
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`, build 84; the executable 1,273,056 bytes, no home folder in its symbols;
  signed with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 29b, the line break (DESIGN.md B4 and R1 amended; 2026-11-03; the user, after seeing a Return come out as a
blank line in the pasted text: "a enter does not put a newline but rather two. Is that intended?", then "newline.",
then: "Wait, make shift+enter newline and keep enter the old behaviour."):

- The model (`Text.swift`): Return still inserts "\n", a paragraph end; ⇧⏎ inserts `Text.lineBreak`, U+2028 LINE
  SEPARATOR, a Character of its own inside the paragraph, which only "\n" ends (`paragraphs`, ⌘←/→ and the line split
  there alone). `insert` keeps a U+2028 as it is and still makes any other newline a paragraph end. ← → ⌫ ⌦ take it as
  one Character; the word moves and word deletes take it as white space (it is, to `Character.isWhitespace`); a
  selection runs across it; `selectedText` (⌘C, ⌘X) gives it as "\n". The journal stores it in the existing
  `insert(at:)`; the replay is unchanged.
- The line (`Line.swift`): `Line.lineBreak`, ` ↵ ` (U+21B5, which Menlo has, one cell as ¶), muted, the arrow in
  `markFont` and the spaces in the line's face, as the ` ¶ `; `Text.runs` (now internal) makes both marks, and
  `Line.width` and `Line.shown` (an entrance's units) go through it; `attributed` puts the mark face on the one
  Character of a mark run that is no space.
- The keys (`LineView.swift`): AppKit sends `insertNewline:` for ⇧⏎ as for Return (StandardKeyBinding.dict has ⌃⏎ →
  `insertLineBreak:`, ⌥⏎ and ⇧⌥⏎ → `insertNewlineIgnoringFieldEditor:`, no ⇧⏎; seen by sending the key events through
  `interpretKeyEvents` in a probe that showed no window), so `doCommand(by:)` takes `insertNewline:` with ⇧ in
  `NSApp.currentEvent`'s flags, `insertLineBreak:` and `insertNewlineIgnoringFieldEditor:` as a line break, with
  Return's click and the ambience's `.paragraph`; ⌃O (`insertNewlineIgnoringFieldEditor:` then `moveBackward:`) opens
  a line. `entering` gives a line break the paragraph fade, as Return's ` ¶ `.
- R1 (`Mechanical.swift`): paragraphs split at "\n" only (was `\.isNewline`, which a U+2028 matches); each paragraph's
  lines (at U+2028) lose their trailing spaces, are joined by "\n" and then go through the rules as one paragraph, so
  a line break is white space to the lone `i` and no sentence end or paragraph start to the capitals (a period's word
  starts after it); two line breaks a blank line. The output holds no U+2028. Not idempotent on a text with a line
  break (its "\n" would come back as a paragraph end); nothing reads R1's output back.
- Not changed: the format-1 journal upgrade (`V1Edit.upgrade`) still splits on any newline, as format 1 meant; the
  site's typable demo, where Enter hands off and no ` ¶ ` shows.
- Tests: 161 (153 before; 8 new: three in EditingTests, one each in CoreTests, MechanicalTests, ThemeTests,
  RenderTests and JournalReplayTests; `paragraphsAndPlainText` types U+2029 for "any newline" and keeps a U+2028),
  debug and release. Renders: `line-break.png`, `line-break-still-day.png`, their `-as-paragraph` twins (the same line
  with a ` ¶ ` in place of the ` ↵ `), `line-break-fade-25ms.png` and `line-break-25ms.png`; the 35 earlier renders of
  the line, the ambience and the hand-off byte for byte as pass 29's (rendered again at its commit and compared).
- Build: `LEMNA_VERSION=0.1.2 make-app.sh`, build 85; the executable 1,274,112 bytes, no home folder in its symbols;
  signed with "Lemna Dev" (`Authority=Lemna Dev`) and verified.

Pass 30, paste, undo and redo (DESIGN.md B4 and E2 amended; 2026-11-03; the user: "It should be possible to paste text
as well. I wanted for example to paste the name of a Obsidian note that contained an emoji but with the current
implementation this is not possible. Add this functionality, but also include a undo function with a corresponding
shortcut."):

- ⌘V (`LineView.paste(_:)`, `Clipboard.read`): the pasteboard's plain text (`string(forType: .string)`), nothing when
  there is none, through `Text.pasted`: a run of two or more newlines of any kind ("\r\n" and "\r" one each) one
  paragraph end, a single one a line break (U+2028), the ones at the very end dropped, a tab one space, the rest
  verbatim; then `Text.insert`, over the selection as typing, one edit, one click (a letter's, a space's when all white
  space), one ambience event. Pending text gives way to it (`discardMarkedText` once `marked` is empty). No ⇧⌘V or
  ⌥⇧⌘V: AppKit sends them only to a menu item of their own (StandardKeyBinding.dict has no ⌘ key), and the paste is plain
  already.
- ⌘Z and ⌘⇧Z (`History.swift`, LemnaCore; `LineView.undo(_:)`, `redo(_:)`): each key's edit is recorded with its kind
  (`History.Kind`: typing, deleting, alone) and its time by `recorded`, a move or a change of the selection closes the
  group (`take`); a key joins the last group when it is open, of its kind, starts where that group ended and comes less
  than `History.pause` (1 s) after its last key; ⌘V, Return, ⇧⏎ and ⌘X are alone. A group keeps the text before and
  after it; `Text.become` goes from one to the other by one delete and one insert of what differs (the whole text when
  the cut's ends would join regional indicators), the caret and the selection as they were, and its motion is the text
  before the caret gaining and losing at its end, so `show` glides it and fades in what came back. ⌘Z plays ⌫'s click
  and the ambience's ⌫, ⌘⇧Z a letter's and a glyph. `load` empties the stack (the silent restore, a finished session).
- The menu (`main.swift`): Edit is Undo ⌘Z, Redo ⌘⇧Z (key equivalent "Z", the mask ⌘ alone, the capital holding the
  ⇧, as AppKit's own menus have it; in a probe that sent key events to `performKeyEquivalent` and showed no window, it
  took both a made-up ⇧⌘Z event with "Z" for its characters and one made from the keyboard's own (characters "z",
  without modifiers "Z"), where "z" with ⌘⇧ as the mask took only the second; ⇧⌘V and ⌥⇧⌘V reached no ⌘V item), Cut,
  Copy, Paste ⌘V, Select All; the box's `sendEvent` hands them to the menu as before.
- The glide (`LineView.edited`): an edit's glide starts at most a band's width away, as a caret move's slide does.
- Tests: 172 (161 before; 11 new: nine in EditingTests, `aPastesNewlinesBecomeLineBreaksAndParagraphEnds`,
  `aPasteReplacesTheSelection`, `anEmojiPastedIsOneCharacter`, `typedRunsUndoAsOneGroupUntilAPauseOrAMove`,
  `deleteRunsUndoAsOneGroup`, `aPasteReturnAndALineBreakAreEachAGroup`, `aNewEditClearsRedo`,
  `undoAcrossASelectionReplacementRestoresTheSelection`, `undoGivesBackTheTextWhereverTheCaretIs`, through a `Writer`
  that records as the line does; JournalReplayTests `pasteUndoAndRedoReplayThroughTheJournal`; RenderTests
  `emojiRenders`), debug and release. Renders: `emoji.png`, `emoji-selection.png`, `emoji-still-day.png`,
  `emoji-still-night.png` (a duck, a flag before the caret, a ZWJ sequence with a skin tone after it, in colour from
  Apple Color Emoji in Menlo's and Literata's lines); the 43 earlier renders byte for byte as pass 29b's. No test
  reaches the Edit menu: the tests depend on LemnaCore alone.

## Known gaps

- Pass 30 is not tried: nothing was built as an app or launched. Untried: ⌘V, ⌘Z and ⌘⇧Z reaching the line in the box
  while Lemna is not the active app (the Edit menu's actions through the non-activating panel, as pass 29's ⌘C), and in
  the window; that macOS shows no paste alert for ⌘V into the box (its read is user originated and paste related, but
  made while another app is active); emoji on real screens and in the Metal strip; the feel of the 1 s pause.

Pass 31, rain on Still water as busy as Code (DESIGN.md A1 amended; 2026-11-03; the user: "The matrix ambient
animation is perfect because it is very busy and yet enough in the background. [...] With the rain animation this is
not the case at all. The rain drops are way to uniform and seem unrealistic. Also its not busy at all. Make it way more
realistic and similar to the matrix effect regarding the intensity."):

- `Water` (`Scenes.swift`): a `Drop` carries what its size (0–1) set when it landed: its crests (1–3), the lead's
  speed, the width, the crater's radius (`near`), the peak, the fade's τ, the lag between its crests and its splash's
  width. `size()` draws the size from a truncated exponential, its slope the intensity's (`waterSize`). The rain lands
  at exponential gaps in drops (`due`), each at the age where in the step its gap ended; the rate (`rate`) is the
  intensity's `waterRate` by the stage's area, times the gust (`gustLevel`: a smoothstep between levels of `waterGust`
  over `waterGustTime`, from its own generator, `gusting`) and the build-in (`buildIn(at:)`, smoothstep over
  `waterBuildIn`). `crest(_:of:)` is crest k's age, radius and alpha (onset, e^(−a/τ), min(1, near ÷ r), `waterFollow`
  per crest), `splash(of:)` the splash's alpha. The intensity is Code's, the same code and constants (`waterFast`,
  `waterRise`, `waterSettle`, `waterHold` are `codeFast` …): every event resets the time since the last key, the
  typing rate sets the target. A word's end drops `wordDrop` as before, now size 1 at `waterWord`; the show's drop too.
  `step` writes through pointers into the scene's own `scratch` (swapped out while it does, as Code's, and asserting
  in debug that it is whole), the narrow rings and splashes from its front and the rings wider than `waterBand` from
  its back, appended after them; `bands` says how many; the drops whose crests have all gone under `waterShown` are
  dropped in the same pass.
- The bands (`Particles.swift`, `Ambience.swift`, `Ambient.swift`): `Scene.bands` (0 by default, Code's) and
  `Run.bands`; `Renderer.encode(…, bands:)` and `offscreen(…, bands:)` draw the last `bands` sprites in a second
  instanced draw (`baseInstance`), 2 × (48 + 1) vertices each; the shader's `Frame.unused` is now `segments`, 0 in the
  first draw, where the vertex shader is as before, 48 in the second, where vertex 2k lies on the outer polygon
  (circumscribing r + 2w + a pixel) and 2k + 1 on the inner circle (r − 2w − a pixel) at angle k; the fragment shader
  is unchanged. `Ambient.draw` passes the run's bands for a frame it draws.
- `Tuning`: new `waterGust`, `waterGustTime`, `waterBuildIn`, `waterFast`, `waterRise`, `waterSettle`, `waterHold`,
  `waterSize`, `waterCrestSizes`, `waterGap`, `waterBright`, `waterFade`, `waterFollow`, `waterLift`, `waterThin`,
  `waterSplash`, `waterSplashWidth`, `waterSplashBright`, `waterWord`, `waterBand`; changed `waterRate` (a pair,
  380 / 620 [0.5]), `waterDrops` 4,000 [32], `waterSpeed` 24–34 by size [36], `waterJitter` 0.1 [0.15],
  `waterSpread` 0.06 [0.15], `waterWidth` 1.2–3 [2–3.5], `waterNear` 8–20 by size [12], `waterOnset` 0.08 [0.18],
  `waterPeak` (1, 0.9) [(0.6, 0.4)]; gone `waterStart`, `waterTrough`, `waterTroughShare`, `waterDecay`.
- The tuning, on the renders and the measures: 1, 300 drops a second, pass 24's peaks (0.6, 0.4), crater 4–10 pt,
  widths 1–2.6: busy, 540 rings, but an eighth of Code's light (0.002 against 0.015), too faint; 2, peaks (0.9, 0.8),
  crater 8–20, widths 1.2–3: 0.69 of Code's on one seed in a gust, 0.45 over four, and the large drops' crests 4–8 pt
  apart at 0.6 read as targets; 3, the crests 2.5–5 pt apart
  at 0.5, 6 % slower; the build-in over 4 s held 82 % at 4 s, over 3 s 93 %; 4, the GPU at twice Code's at rest and
  three times typing, from the wide rings' squares: the bands; 5, 380 / 620 drops a second and peaks (1, 0.9): 0.66 of
  Code's light, the lift 2.78 times (Code's 2.70); the step through pointers (debug 4.7 → 2.3 ms typing on
  2560 × 1440).
- Tests: 166 (161 before), debug and release. New: `stillWaterRainsInGustsAtItsRateScaledToTheScreen` (the rate over
  600 s, the gusts' spread, drops of one frame at different ages, the Clark–Evans ratio), `dropSizesAreManySmallFewLarge`,
  `aDropsSizeSetsItsRings` (crests, splash, 1/r and the fade, thinning, life), `stillWaterAtRestIsHundredsOfRingsAtOnce`,
  `stillWaterBuildsInAtTheSummon`, `typingMakesTheRainHeavier`, `stillWaterStaysUnderTheCapAndWithinCodesStepBudget`,
  `aRingDrawnAsABandIsTheRingItsSquareDraws`, `stillWaterRenders`, `stillWatersFrameCostsTheGPUAboutWhatCodesDoes`;
  `stillWaterDropsOneForEachWord` replaces `stillWaterDropsOneForEachWordAndNoneForAKey` (keys now raise the rain);
  gone with pass 25's behaviour `stillWatersRestRateHoldsWhileWriting`, `aDropsRingsRiseSoftlyThenFadeWithRadiusAndTime`,
  `stillWaterStaysUnderTheCapOnALargeScreen` and `stillWaterShowsOnStillsDayAndNightDim`; the tuning record.
- Renders (app/renders): `ambience-water-build-0ms.png`, `-500ms`, `-2000ms`, `-4000ms`, `ambience-water-idle.png`
  (20 s at rest) and `ambience-water.png` (10 s of typing), Lemna's; `ambience-water-day.png` and
  `ambience-water-night.png` (Still at rest, as before named) and their `-typing` twins. Every other render byte for
  byte as pass 29b's (rendered at its commit and compared), Code's among them.
- Measured (on the layer at 1×, the mean light over four seeds; release unless said): see DESIGN A1's pass 31. The
  step 0.019 ms at rest on 1512 × 982 (Code 0.022), 0.095 ms typing on 2560 × 1440 (Code 0.077); the GPU at 2× 0.31 ms
  at rest (Code 0.26), 0.60 typing (Code 0.38).
- No app bundle built; nothing launched.

## Known gaps

- Pass 31 is not tried: nothing was launched, and the renders are single frames. Untried: the rain's motion at 30 Hz
  on a real dim (whether hundreds of rings read as rain or as a flicker in the periphery, whether the splashes
  twinkle or nag), the gusts' sway, the 3 s build-in, the lift while typing, the bands on a 1× screen and a 6K
  display, and the power at rest. The site's Still water tile still draws pass 25's drops.
- Pass 29b is not tried: nothing was launched. Untried: ⇧⏎, ⌃⏎ and ⌥⏎ in the box and the window (that the panel's key
  event carries ⇧ to `doCommand`), the ` ↵ `'s look by day and night, a paste of a line break into other apps. Open: a
  saved Markdown file shows a lone "\n" as a space in a Markdown viewer; no hard break was added.
- Pass 29 is not tried: nothing was launched. Untried: ⌘A, ⌘C and ⌘X reaching the line in the box while Lemna is not
  the active app (the Edit menu's actions through the responder chain of the non-activating panel; the box's
  `sendEvent` hands ⌘ keys to the menu as for ⌘⏎), and in the window; the band on real screens by day and night and
  under Increase Contrast; dead keys and an input method over a selection; the feel of ⌘A's glide to the end. Not
  built: ⇧↑/⇧↓, ⇧Home/⇧End, ⌘⌫, the mouse (⌘V into the line and undo since pass 30).
- Pass 28 is not tried: nothing was launched or played. Untried: each new bed under the clicks while typing, on the
  built-in speakers and on headphones; whether the 120 Hz low cut is "a bit" on Ship and Lab; Lab's blips, 3.5 dB
  nearer the clicks after the levelling; Space's swells and Synth's chords against writing (they fail sound.md's
  steadiness rule, the user's pick); Synth's wrap from one chord to another every 90 s.
- Pass 27c is not tried: nothing was launched, and the main thread's frames are read from the crash report and
  QuartzCore's disassembly, not seen. Untried: typing for minutes with Code without a crash; that the rain does not
  stutter while typing (frames handed to the scene thread); whether a handed-over frame also comes on the scene
  thread (then drawn twice, harmless). Address Sanitizer does not run here (refused by the test runner, deadlocking
  in an own binary on macOS 26.5), so the pointer paths are checked by debug assertions only.
- Pass 27b is not tried: nothing was launched. Untried: whether 4 s of build-in reads as arriving or as slow, and
  the build-in at 30 Hz on a real dim (the renders are single frames); whether the lift is "just a bit more" or now
  too much; the lift's onset, set mostly by the typing rate's 2 s window (a 1 s window would bring it in about twice
  as fast; not built). The site's Code tile still draws pass 25's rain.
- Pass 27 is not tried: nothing was launched. Untried: the look on a real dim at 30 Hz (the renders are single
  frames), whether the rest state is too busy beside the box, whether the halo reads as a glow, whether the near
  sheet's mipmap blur looks soft or blocky on a 1× screen (the atlas has two levels below its own), the mirrored
  katakana (Hiragino Sans W6) beside Menlo's digits, a 6K display's 15,000 sprites at 60 Hz. Not built: the films' green
  haze (a bloom over the whole screen). The site's Code tile still draws pass 25's rain.
- Pass 26 is not tried: nothing was launched, and the cause is read from the code and AppKit's header, not from a log.
  Untried: the relaunch itself, ⌘Tab and the Dock with the box up; whether the Accessibility prompt's process comes to
  the front (then the box goes once the app behind is back after it) or takes the keys without (then the box stays
  with its note until a click into it and Esc, or ⌃⌥Space); ⌃⌥Space bringing the save panel back with its keys after
  another app came to the front; whether something that should leave the box alone activates an app (an input method's
  or the emoji picker's window, a launcher: none is known to); a Space switched by gesture now hides the box, as its
  app comes to the front. macOS shows the Accessibility prompt once, and the grace cannot tell whether it did: for 2 s
  after a ⌘⏎ that copied for want of the permission, a click outside leaves the box up without the keys (⌃⌥Space or a
  click into it takes them back).
- Pass 25 is not tried: nothing was launched. Untried: whether 8–16 rows a second reads right at rest and while
  typing, and whether the density building over a few seconds (new heads start at the top) feels like "more intense"
  or slow; whether a drop per word on the water feels calm or busy at a fast pace (at most one every 0.8 s), and where
  the drops land on a real screen. A hand-off's end of text drops no word (HANDOFF asks).
- Pass 24 is not tried: nothing was launched. Untried: whether the water reads by eye on a real wash (its alphas are
  look §5.3's and the panel's, a starting value; by night it is faint), whether a drop every 8 s or so feels like a bed
  or like waiting, the drop above the box at the summon as the box fades in, the ring's Core Animation layers against
  the render (borders on growing rounded layers; Still's corners are circular arcs, the box's too until a continuous
  curve comes), the even lift beside the curve elsewhere, and whether the dim windows staying 1.2 s after the paste
  disturb the app behind (they take no clicks). Under Reduce Motion the hand-off goes at once, as before, not as a fade.

- Pass 21 is not tried: nothing was launched. Untried: Still over light and dark apps in both appearances; the window's
  and the panel's `.aqua` (the traffic lights, the sheets); the fade open and the fade hand-off; Rain's ink on the
  wash by eye; a theme switch in the window. A theme chosen while the box is up shows at its next summon, and so does
  a change of the appearance or of Increase Contrast while it is up (before the pass Increase Contrast's grey was taken
  then, drawn at the next key). Under Still: Drift shows nothing (its glyphs are the line's, the atlas is Menlo; RM1
  removes Drift). Not built: MO1's ring.
- Pass 22 is not tried: nothing was launched. Untried: Literata registering from the bundle at launch (the tests
  register it from `app/Fonts`; a failure is in the system log and Still shows Charter); the continuous corners and the
  rounded caret ends on screen; the unsmoothed type by eye at 1× and 2× (measured only against the panel's browser);
  Increase Contrast's darker caret. Under Increase Contrast the hairline stays 1.30:1 (LK1 gives no variant; the box
  is still told apart by its warm paper on the cool wash). With a proportional face a caret move or a deletion across a
  kerned pair or a ligature moves the text by a point or two at the move's start: `Line.width` measures what passed on
  its own, and the two shaped lines differ by the pair's kerning or the ligature's width.
- The release executable is not stripped: the debug map in its symbol table names the build folder's absolute paths
  (source and object files). `strings`, which earlier passes used for the "no `/Users/` path" check, does not read that
  table; `nm -pa` does. `strip -S` on the executable before signing, or the linker's `-S`, would drop it.

- Pass 20 is not tried: nothing was launched and nothing registered. `SMAppService.mainApp` registers the bundle at
  the path it has then: if Lemna.app is moved, the login item breaks until Start at Login is turned off and on again,
  so turn it on once Lemna.app is where it stays (Applications; a download opened in place may run from a translocated
  path). Untried too: whether ServiceManagement takes the self-signed "Lemna Dev" signature (it wants a signed app; an
  ad-hoc build may be refused), and what an ad-hoc rebuild does to a registered item.

- Pass 19b is not tried: nothing was launched. Untried: whether the idle rain reads as low-key or too faint (head
  0.35, trail from 0.20 over the dim; matrix §6.2) and as "covering the whole screen" with about a quarter of the
  columns showing a head; that the link really runs at 30 Hz at rest (set, not measured); the cost of the link running
  while the box is up (`powermetrics`, HANDOFF); the rain appearing a frame or two into the dim's 300 ms fade-in at
  its full alpha, not fading in with it.

- Pass 18 is not tried: nothing was launched. Untried: whether the 80 ms glyph fade reads at speed or not at all
  (`Tuning.glyphFade`; 0.140 is the scale's next step); the hand-off at 260 ms; the glyph fade left on under Reduce
  Motion.

- Pass 17b is not tried: nothing was launched. Untried: that the hidden strip and the glyph layers reach the screen in
  the same frame (a doubled or a blank frame at ⌘⏎ would say not); that the ghost takes over without a jump at Return's
  key-up (Core Animation's `beginTime` in the past on new layers); that AppKit leaves the content layer's collapse
  animations alone; that `canHide` off keeps the ghost and the dims up through `NSApp.hide`; how the shadow going at
  the first frame looks over a light app; the motion's feel at 60 Hz, where the glyph at the caret shows in one or two
  frames. The latency budget (key → presented p50/p90 no worse than the spike's 42/60 ms) is not measured.

- Pass 17a is not tried: nothing was launched. Untried: that the monitor gets Return's key-up in the non-activating box
  (the probe sent it through `NSApp.sendEvent` without a window; the 50 ms read of the key's state covers a miss);
  whether 30 ms is enough for every app behind to have its keys back before the ⌘V (a ⌘V that comes too early goes to
  no window: the text stays on the clipboard) and for a password field to turn Secure Input on again (too early: the
  ⌘V goes into the field); the timing log's numbers on this Mac.

- Pass 16 is not tried: nothing was launched. The physical layout comes from KBGetLayoutType, which the SDK no longer
  declares: if a macOS drops it, ISO keyboards take ANSI's places (only the four keys that differ move). A keyboard
  plugged in after the summon is read at the next summon.
- Pass 15b is not tried: nothing was launched. The fix is checked by the lifecycle's tests and on a real layer and
  link without a window; the display link's callbacks in a shown dim and the main thread's show after a cleared frame
  are not.
- Pass 15 is not tried: nothing was launched. Untried: that `CAMetalDisplayLink` fires on the scene thread's run loop
  and keeps off the main thread (the panel's "to verify"); the key's latency with a scene playing (the budget: p50/p90
  no worse than the spike's 42/60 ms, measured with os_signpost; not done); whether Core Animation composites the
  layer's added light where a pixel's colour passes its alpha (overlapping sprites) or clamps it (either way it shows);
  the scenes over a light app (C1: they nearly vanish there); the GPU memory of a playing screen (up to three
  screen-sized drawables, about 24 MB each at 2× on a 14-inch screen, let go at the pause); Rain and Return's beam on a
  second screen. The renders (`app/renders/ambience-*.png`) are the Metal pipeline's own frames over a drawn dim.
- A box dragged to another place keeps its scene where the box was until the next summon (the stage is taken at each
  show). Reduce Motion turned on while the box is up stops the ambience only at the next summon.

- Pass 14b is not tried: nothing was launched. Whether the new magnitudes are now plain without being too much (the
  knobs are `Effects.Tuning`'s), and whether the 3 pt rise makes the line look jittery at speed.
- Pass 14 is not tried: nothing was launched. Untried: the open and close's feel and whether Esc feels slow with the
  fade; whether the ghost hands over from the box without a blank frame (`CATransaction.flush` before the box goes);
  how the system shadow behaves while the content grows (taken again at the end); whether AppKit's window-alpha
  animation keeps `quint`; the pop-in at speed; the sheen against the paste's timing; B2 and K3; the dim over light
  and dark apps; the box's look under Reduce Motion and Increase Contrast. The app icon (L1) keeps its old colours.

- Pass 13 is not tried: nothing was launched; nothing showed the new name, the Accessibility prompt for the new id,
  or a Flow session coming along in the real keychain (the tests use a key store in memory).

- Pass 12 is not tried: the mark has not been seen in the real menu bar, nor the icon in Finder or System Settings.

- Pass 11 is not tried, and nothing in its packs was listened to: their filters, spans and levels are by
  measurement (`lib/LemnaClicks/THIRD_PARTY.md`). On a MacBook the Soft pack may double the key under the fingers.

- Pass 10 is not tried (the builder shows no windows; the note was not drawn).
- A paste finishes the session right after its ⌘V goes out (before it until pass 17a): if the ⌘V does not land (no text
  field has the keys in the target, the target ignores posted keys), the text is no longer in Lemna, but since pass 11
  it is still on the clipboard, one ⌘V away. Before pass 11 the old clipboard came back 250 ms after the ⌘V and the text
  was then nowhere; before pass 10 the 10 s grace's Undo covered it. The clipboard the user had before a paste is gone,
  as after any copy.
- Done from the menu-bar item with the box hidden brings the box up first (to record the app in front and to have a
  place for a note), so on a paste it shows for a moment before it goes.
- Pass 8 is not tried (the builder shows no windows; the line was drawn offscreen, `editing.png`,
  `move-left-70ms.png`). Untried: how the glide of a held ← and of ⌘← feels, and whether a Character passing under the
  caret on a move reads as moving or as blinking (the alternative, not clipping during a move, would draw text over the
  caret, which S1 rejected); whether the accent menu and input methods place themselves right with the caret mid-text;
  ⌘← and ⌘→ in the box (they reach the view because the main menu has no item for them).
- A caret move during an insertion's glide moves the Character it passes from one part to the other, and with it from
  the insertion's offset to the move's: it may shift by what remains of that glide, under one advance.
- The text after the caret is shaped up to 300 Characters (200 until pass 22): in a window wider than about 11,000 pt
  (Literata 30, Charter 31; 14,000 under Menlo) its fade would end early.
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
  the line and on disk; since pass 17a that comes after the paste, Copy or Save went out, with the box back for the
  alert.
- Journals `open` reports as unreadable (noise of finished sessions) are left on disk.
- Whether a frame presented while one is already waiting for the same refresh replaces it or queues behind it is not
  documented; with two drawables a queue costs at most one frame. Measure if typing during a glide feels behind.
- Pending text from multi-stage input methods (Japanese, Chinese) is drawn as plain text, without the underline or
  the selected clause.
- No accessibility: VoiceOver does not see the text yet.
- The bundle identifier `dev.lemna.app` is for personal builds: lemna.dev belongs to someone else. Change it before a
  public release if a domain of your own exists (DESIGN.md N, X1); a new id resets the Accessibility grant, the
  keychain item's access and the settings, as the rename did.

Pass 32, the launch defaults (DESIGN.md TH1, K1 and A1 amended; 2026-11-04; the user: "Make the current lemna settings
the default settings when launching the app.")

- `main.swift` registers the launch defaults in UserDefaults: `sound` on (as before), `bed` Lab, `ambience` code,
  `theme` still. A key once written by a menu keeps its own value; a kept value since removed falls back as before
  (no bed, no ambience, the first theme). The first pack (`soundPack` unset) and every effect on were the defaults
  already. Still's preset (Stone pack, Rain bed, Still water) is unchanged: it is what choosing Still from the Theme
  menu writes.
- No test: the registration is in the app target, which the tests do not link. Build: `LEMNA_VERSION=0.1.2
  make-app.sh`, signed with "Lemna Dev".

## Known gaps

- Pass 32 is tried only on a Mac whose defaults were already set by the menus; a fresh install (`defaults delete`
  the app's domain) has not been launched.

Pass 33, the dim over the menu bar (DESIGN.md W2 amended; 2026-11-04; the user: "Currently when I run Lemna the
background ambient animation does not extend to the menu bar. It should though.")

- `Box.swift`: `Box.level`, NSStatusWindowLevel + 2, for the box and the ghost; the dims one level under, as before.
  The dims were at floating − 1, under the menu bar (24), its status items (25) and the Dock (20), so the shade and the
  scene stopped at the menu bar's edge though their frames were the screen's. Menus and pop-ups (101 up) stay above;
  the dim ignores the mouse, so the menu bar and the Dock stay clickable through it. Built and signed.

## Known gaps

- Pass 33 is not tried: whether the menu bar's status items (a window manager's workspace indicator among them) show
  dimmed under the scene, and whether anything of the system's that should stay bright (notification banners, the
  Control Centre's pop-overs) now sits under the dim.

Pass 34, Still's preset (DESIGN.md TH1 amended; 2026-11-05; the user: "Make the Still preset Code + Lab bed too.")

- `Theme.still.defaults` is the Stone pack, the Lab bed and Code (was the Rain bed and Still water), so Theme ▸ Still
  writes what a fresh install starts with (pass 32); its item reads "Still (lab bed)". ThemeTests follow.

Pass 36, Settings and the summon chord (DESIGN.md SP2, W2 amended, Open 7 closed; 2026-11-06; the user's picks
`SP2 SK1 SR1 SC2 SW3 SD2` of `docs/design-panel-lemna-settings.html`, evidence in `research_notes/Lemna settings/`)

- Settings… ⌘, in the menu-bar item's menu (above Start at Login) and in the hidden Lemna menu, so ⌘, works from the
  box and the window. It opens "Lemna Settings" (`Settings.swift`): a plain titled window at the normal level, system
  controls and appearance, one row: "Show Lemna:", the field, Reset to ⌃⌥Space (grey while the chord is ⌃⌥Space),
  and a grey line under them. Opening it from the box hides the box first (the session stays); a summon while it is
  up orders it out before the box shows; it is off while a hand-off, a question or a sheet holds the container.
  `activateLemna()` brings it forward (the 0.2 s fallback now also while it alone is up); closing it (its button,
  Esc, ⌘W) calls `handBack()` unless the window mode's window is up. ⌘W is a new Close item in the hidden Session
  menu, which presses the key window's close button; in window mode that is back to the box, as the button.
- The field (`Recorder`): a click, or Space or Return with the focus, starts listening; the hotkey is unregistered
  meanwhile (`Hotkey.paused`); a local monitor takes every key-down first, the held modifiers show; the next chord goes
  through `Chord.verdict` (the rules, the main menu's key equivalents read from the menu, `CopySymbolicHotKeys`'
  enabled entries): refused, the line says why and the field listens on; taken by macOS, kept with the warning; else
  kept. ⌫ alone and the × clear (`hotkey` = `{}`), Esc alone or a click elsewhere cancels, Reset removes the key.
- `hotkey` in UserDefaults, `{key, modifiers}` (Carbon's key code and mask), registered as ⌃⌥Space's default with the
  others. At launch the kept chord is registered as it is (`Chord.kept`: what does not decode or is refused reads as
  the default). The menu-bar item's menu is the App's delegate: as it opens, macOS's list is read again and Show Lemna
  carries the chord, or, while it is taken (or RegisterEventHotKey refused it), no chord and a grey line under it,
  "⌃⌥Space: taken by macOS" or "…: not available". The glyphs follow the current ASCII-capable layout
  (`layoutLetter`, UCKeyTranslate), the US table when it cannot be read.
- Tests: 182 (177 before; new in `ChordTests`: the glyphs and the key equivalent, the storage round trip and bad
  values, the rules, Lemna's own keys and the system's with the Fn bit masked, the menu's and the window's lines).
  Debug and release build without warnings; `make-app.sh` not run.

## Known gaps

- Pass 36 is not tried: nothing was launched, and the window, the field and the registration are the app target's,
  which the tests do not link. Untried: Settings… from the menu-bar item, from the box (⌘,) and from the window, the
  window coming forward with the keys and the app before coming back on close (button, Esc, ⌘W); a summon while it is
  up; the field's real key events (a click and Space or Return to listen, the held modifiers, ⌘S and ⌘Q taken by
  the field, Tab, ⌫, the ×, Esc, a click elsewhere, the window losing the keys), the hotkey paused while listening
  (pressing ⌃⌥Space records it rather than summoning) and registered again after; the refusals' lines (⌥K, ⌘L, ⇧⌘↩);
  a chord macOS has on (⌃Space with the input-source shortcut on) kept with the warning and working once that is off,
  without a relaunch; a chord another app holds (that app reacts, the field sees nothing; no check can tell); a German
  layout (⌃⌥Z reads Z); the menu's chord and its grey line; VoiceOver on the field and its focus ring; ⌘W in the box
  (Close is disabled there; whether AppKit swallows the key or hands it on to the line, which ignores it, is unseen).

Pass 37, sound and the box's chords in Settings (DESIGN.md SP2 amended; 2026-11-06; the user's follow-up decision of
2026-11-06)

- `Settings.swift`: the window's one page is an `NSGridView` of three groups under bold labels with separators:
  Shortcut (pass 36's row, unchanged), Sound (Play sound, Clicks and Bed pop-ups with Sound ▸'s items in its order
  and names, No bed last) and Shortcuts in the box (`Shortcuts.overview`, the chords in the monospaced system face and
  what each does, small system font, read-only). The help line keeps two lines' height and wraps at the row's width,
  so the window does not change size; it is 427 × 517 pt inside the title bar, measured offscreen with a throwaway
  build of the window's code (not kept).
- The Sound group calls the menu items' own actions: the checkbox `toggleSound(_:)` (⌘K's Off), a pop-up's chosen item
  `chooseSound(_:)` or `chooseBed(_:)` with the item's tag as the menu's. `keepSound()` and `keepBed()`, which every
  change of the sound goes through (the window, Sound ▸ in either menu, ⌘K, a theme's preset), end with
  `settings?.refreshSound()`, and `show()` reads it too, so the group always shows the model. A pack or a bed chosen
  while the sound is off turns it on, as in the menu; the pop-ups show the kept pack and bed in either state.
- `Shortcuts.swift` (LemnaCore): the fourteen rows, each its chords and a label, checked against `mainMenu()`'s key
  equivalents and `LineView.doCommand`; letters from the US table, as the menus' key equivalents are characters.
- Tests: 183 (182 before; new `theOverviewListsEachChordOnceAsMenusWriteIt`: no chord or label twice, every chord
  printable, the glyphs in order, every ⌘ chord but the caret's moves one of the main menu's key equivalents as the
  tests' copy of `mainMenu()` has them). Debug and release build without warnings; `make-app.sh` not run.

## Known gaps

- Pass 37 is not tried: nothing was launched. Untried: the window's look (the groups, the separators, the list's
  faces) by day and night; the checkbox and the pop-ups changing the sound, the bed and the menus' ticks; ⌘K, Sound ▸
  and a theme from the menu while the window is up updating it; Tab through the controls; the height on a small
  screen (measured, not seen).

Pass 38, Emoji & Symbols from the box (DESIGN.md B4 amended; 2026-11-06; the user's decision of 2026-11-06)

- `main.swift`: an Emoji & Symbols item, ⌃⌘Space, in the hidden Edit menu after Select All, to `App.showCharacters`:
  the container key with the line as its first responder, `activateLemna()`, then `NSApp.orderFrontCharacterPalette`
  once Lemna is active (`didBecomeActiveNotification`, given up after 1 s; at once in the window, where Lemna is
  active). The box's `sendEvent` hands ⌃⌘Space to the menu as its other ⌘ chords. Disabled while no container is up, a
  hand-off or a question holds it, or a sheet is on it. At launch an Emoji & Symbols item AppKit put into the Edit menu
  itself (`orderFrontCharacterPalette:`) is removed; the SDK's headers say nothing on when AppKit adds one.
- Unchanged and read for it: picks reach `LineView.insertText(_:replacementRange:)`, which needs only the line to be
  the key window's first responder (the box is key whenever it is up, `Box.show`'s `makeKey`), plays a letter's click,
  records a typing group and sends the ambience a glyph without a key code (the caret's place, as the accent menu's
  pick); `appActivated` returns at Lemna's own activation; `target`, the paste's app, is set only at a summon from
  another app, and `bringForward` yields to it when Lemna is active.
- `Shortcuts.overview` lists ⌃⌘Space "Emoji & Symbols"; the tests' copy of the main menu has the item, so the summon
  field refuses ⌃⌘Space as Lemna's own before the system's Character Viewer. The Settings window is 427 × 534 pt
  inside the title bar (517 before), measured offscreen with a throwaway build of its code.
- Tests: 183, as before (`theOverviewListsEachChordOnceAsMenusWriteIt` and `lemnasOwnKeysAreRefusedAndTheSystemsWarned`
  check the new row and the refusal). Debug and release build without warnings; `make-app.sh` not run.

## Known gaps

- Pass 38 is not tried: nothing was launched. Untried: whether ⌃⌘Space reaches the box's menu at all or macOS takes
  it first (the system's list has a Character Viewer chord; if it is on, macOS may open the viewer for the app in
  front before Lemna sees the key); the viewer then targeting the line rather than the app behind; a pick landing in
  the line with its click and as one ⌘Z step; Lemna's
  activation leaving the hand-off alone (⌘⏎ pasting into the app behind after a pick); the viewer left open across a
  hand-off or Esc (it then follows whichever app is in front); the same in the window; an AppKit item appended to the
  Edit menu after launch (Lemna's comes first, so its chord is still Lemna's).
- Pass 38b, fixed: build 101 hid the box as the viewer opened. The viewer runs in processes of its own, and pass 26's
  watch (`appActivated`, NSWorkspace's didActivateApplication) took its coming forward for another app's. The
  identifiers, read from the Info.plists on macOS 26.5: `/System/Library/Input Methods/CharacterPalette.app`,
  "Emoji & Symbols", com.apple.CharacterPaletteIM (LSUIElement), and in
  `/System/Library/PrivateFrameworks/CharacterPicker.framework` two XPC services, com.apple.CharacterPicker
  .RemoteGenerationViewService and .FileService (nothing under `/System/Library/CoreServices`). The watch now ignores
  the first two as it ignores Lemna. A click outside is the panel's resign (`boxLostKeys`, a turn later), no mouse
  monitor; it now also keeps the box when the app in front is the viewer or Lemna itself (which it is after
  `showCharacters`), so only another app taking the keys hides it. Lemna coming back to the front with the box up and
  no sheet on it makes the panel key again (`appActivated`), for when the viewer closes. Untried: all of it, and
  whether closing the viewer brings Lemna back to the front or the app behind (which would hide the box as before).

Pass 39, the ambience in Settings alone (DESIGN.md SP2 and A1 amended; 2026-11-06; the user's decision of 2026-11-06)

- Ambience ▸ is gone from the menu-bar item's menu and from the hidden Session menu (`ambienceMenu` and the submenu's
  case in `validateMenuItem` with it); Theme ▸ and Effects ▸ are unchanged. The Settings window has an Ambience group
  between Sound and the box's chords: "Mode:", a pop-up of Code, Still water and Off with the submenu's tags, whose
  choice goes to `chooseAmbience(_:)` as the submenu's items did (the default written, the box given the mode, the
  path a theme's preset takes). `keepAmbience()` ends with `settings?.refreshAmbience()`, as `keepSound()` does for
  the Sound group; `show()` and the window becoming key refresh it too. Under Reduce Motion it shows Off and greys the
  modes, as the submenu did. The window is 427 × 599 pt inside its title bar (534 before), measured offscreen with a
  throwaway build of its code.
- Comments that named Session › Ambience ▸ (`Ambience.swift`, `Theme.swift`, `ThemeTests`) now name the window.
  The site's script comments still say Ambience ▸ (site/assets/site.js; not the app).
- Tests: 183, as before (none named the submenu; the tests' copy of the main menu has only key equivalents). Debug and
  release build without warnings; `make-app.sh` not run.

## Known gaps

- Pass 39 is not tried: nothing was launched. Untried: the pop-up switching the mode (Code to Still water to Off and
  back) and the box's dim showing it at the next summon; Theme ▸ with the window up moving the pop-up to the preset's
  mode; Reduce Motion turned on and off with the window open (read when it becomes key); the window's new height on a
  small screen (measured, not seen).
