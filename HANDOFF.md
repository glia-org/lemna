# Handoff

`DESIGN.md` holds the decisions and the plan. This file says what is done and what is next.


**Known crash (2026-10-28, pass 15 as pushed): Esc while a session is open kills Lemna** when an ambience mode is on (three crash reports; thread `dev.lemna.ambience`, an Objective-C exception out of the `CAMetalDisplayLink` callback during the dim layer's teardown, from `SceneThread.main` at `Ambient.swift:31`). Workaround: Session › Ambience › Off. The fix is in progress on branch `wip/esc-crash` (lifecycle type + tests done, the scene-thread rewrite of `Ambient.swift` not); the user stopped work to shut the machine down. Resume there: finish the teardown order (pause and invalidate the link on the scene thread before any layer or drawable change, callbacks ignored after invalidation, `nextDrawable` nil handled), reproduce with the lifecycle tests, build, then merge to main.

## State (2026-10-28)

- Research, panel, report: done (`docs/`, `reports/`, `research_notes/`).
- Spike GPUI vs AppKit: done, results in `DESIGN.md`; the user chose T2 (Swift + AppKit).
- App, milestone 1 (surface): built in `app/` from `spikes/appkit-line`, tests pass (`app/README.md`), not yet tried
  by the user. Try `open app/build/Lemna.app` after `app/make-app.sh`:
  - Type a few sentences: the line glides left, the new letter comes out from under the caret, the old words fade.
  - Dead keys on the German layout: ´ then e gives é; ⌥U then o gives ö. Holding e should offer the accent menu at
    the caret.
  - Return: a muted ` ¶ ` on the line; twice leaves a blank line (` ¶  ¶ `).
  - Backspace: deletes within the current word only; after a space, or at a paragraph's start, it does nothing.
  - Resize the window (the caret stays at 60 %), full screen (green button or ⌃⌘F), AeroSpace: tiled, keeps focus.
  - Esc, arrows and clicks do nothing.
- Libraries: `lib/LemnaJournal` (milestone 2, E2) and `lib/LemnaClicks` (milestone 4, K1), committed with their tests.
- App, milestones 2 and 3 (the journal in the app; Done → review → copy / save / discard; R1): built, 36 tests pass
  (`app/README.md` says what each part does). The review sheet, R1's undo and the 10 s grace went in pass 10 (below),
  and with them this list's items on the sheet, Done, Back, Copy, Save and Discard. Try, after `app/make-app.sh` (the
  first launch makes a key in the login keychain; after each rebuild macOS may ask once whether Lemna may use it, as the
  ad-hoc signature changed: Allow):
  - Restore: type, ⌘Q, relaunch: the text is back without a dialog, the line ending where it was. The close button
    hides the window; the Dock icon shows it again with the text.
  - Crash: type steadily and run `pkill -9 -x Lemna` from a terminal mid-word; relaunch: everything but the last
    ≤ 50 ms is there.
  - The folder: `~/Library/Application Support/Lemna/sessions.noindex/` holds one `<uuid>.journal` per session; after
    a paste, Copy, Save or Discard that file is gone and the new session's takes its place. `tmutil isexcluded` on the
    folder says excluded.
- App, the clicks (K1) and milestone 5 (W1 summoning, M1 session frame; Plan items 4 and 5): built, 44 tests pass
  (36 before, 8 new), `make-app.sh` assembles, signs and verifies the bundle with the click pack inside. v1 is
  complete as planned. The session frame (M1) went in pass 10, and with it this list's items on the time box, the
  intent, the review's ⌘⏎ and the log. Try, after `app/make-app.sh`:
  - Clicks: type; each letter, space, Return and deleting backspace clicks, before the line moves. A backspace that
    does nothing (after a space, at a paragraph's start) is silent.
  - Sound: ⌘K silences (since pass 11 it ticks Off in the Sound submenu); relaunch: still off. ⌘K again: on.
  - Bluetooth notice: with Bluetooth headphones as the output (at launch, or switch to them while Lemna runs):
    `Bluetooth output: clicks arrive late · ⌘K mutes`, small and grey, centred near the bottom edge, fading after 5 s;
    once per switch, not again for the same output. With the sound off: no notice, until ⌘K turns it on.
  - Hotkey ⌃⌥Space from another app: Lemna's window comes to the front, key, ready to type. Again: Lemna hides and the
    other app is back. Also after the close button and after ⌘M.
  - Menu-bar item: a small line with a caret bar, light or dark with the menu bar. Its menu: pass 10 lists it.
- Known for these (details in `app/README.md` Known gaps): `NSApp.activate()` may not bring Lemna forward from a hotkey
  under macOS 14's cooperative activation (untried; the deprecated call is the fallback); ⌃⌥Space is macOS's default
  "Select next source in Input menu" where that shortcut is on.
- App, pass 6 (W2 the box, O3 paste at Done; Plan item 6): built, 51 tests pass (44 before, 7 new: the box's frame
  and clamps, the review grown from the bottom edge, one container at a time, the paste's decision table, the restore
  rule, the pasted grace), `make-app.sh` assembles, signs and verifies the bundle, now with `LSUIElement`. Not tried:
  the builder showed no window. `app/README.md` (Pass 6) says what each part does. It changes some of v1's lists
  above: nothing shows at launch and there is no Dock icon or menu bar (the menu-bar item is the menu; pass 10 lists
  it); Esc hides the box; ⌃⌘F is Open Window (full screen only from the window's green button); the window's close
  button returns to the box. Pass 10 took out this list's items on the review (Done in place, Paste from it, Undo
  after a paste, Secure Input, No target, the time box and intent questions); its own list has the paste and the
  copy notes. Try, after `app/make-app.sh` and `open app/build/Lemna.app`:
  - Summon from another app (TextEdit, say): ⌃⌥Space or the menu-bar item's Show Lemna. A dark rounded box about 60 %
    of the screen wide, a line tall, centred in the lower third of the screen with the pointer; every screen dimmed
    around it, the menu bar and Dock not. The app behind stays active (its name stays in the menu bar).
  - Type: the line glides as in the window; dead keys (´ then e), ⌥U then o, the accent menu on a held e, clicks.
  - Esc: box and dim gone at once, the app behind has the keys. Summon again: the text is still there.
  - Hotkey while the box is up: it goes. Click into another app through the dim, then the hotkey: the box takes the
    keys back.
  - Hold ⌘⏎ a little long at the paste: the box waits for Return to come up, so no repeated ⌘⏎ reaches the app
    (which would send a message in many apps).
  - Window mode: ⌃⌘F in the box (or Open Window in the menu-bar item): the box goes, Lemna comes forward with v1's
    window and the same text, the line at 60 % of the window. ⌃⌘F again, or the close button: back to the box. In
    full screen (green button), ⌃⌘F leaves full screen first, then the box.
  - Over a full-screen app (Safari in full screen): the box and the dim show over it.
  - AeroSpace: it leaves the box and the dim alone (they float); whether it still tiles the window now that Lemna has
    no Dock icon is open.
  - Discard… from the menu-bar item with the box hidden: the box comes, with the question as a sheet on it.
- App, pass 7b (a click outside hides the box; the pass also brought Harper's review, R2, Plan item 7, which pass 9
  removed): built, signed and verified; its one test that stays is the click-outside guard's table. Not tried: the
  builder showed no window. `app/README.md` (Pass 7b) says what it does. Try, after `app/make-app.sh` and
  `open app/build/Lemna.app`:
  - Click outside: with the box up, click into another app or on the dim: box and dim go at once, that app has the
    keys; summon again: the box is back as it was. Not while a question or the save panel is up on the box. Typing
    with the accent menu (hold e) or an input method should not hide it: watch for that.
- App, pass 8 (B4 editing anywhere on the line, which replaces B1; Plan item 8): built, 74 app tests pass (65 before,
  adapted: B1's backspace test now checks ⌫ across spaces and paragraph ends; and 9 new: every key of B4 with its boundaries, the word rules, Characters with é, 🙂 and 👩‍💻, typing in
  the middle, the replay of every key's edits, the line's two parts, the after-part's fade, the move glide's cap and
  limit), and the journal's 14 (10 before, adapted, and 4 new: format 1 replayed as its text, its move to format 2 in
  order, a refused move leaving format 1 as it was, a format 2 round trip with edits in the middle; the login-keychain
  test skipped as before). `make-app.sh` builds, signs and verifies. Not tried: the builder showed no window (the line
  was drawn offscreen: `app/renders/editing.png`, `move-left-70ms.png`). `app/README.md` (Pass 8) says what each part
  does; the journal's format 2 is in `lib/LemnaJournal/README.md`. It changes v1's list above: ⌫ deletes across spaces
  and paragraph ends, and the arrows move the caret. Try, after `app/make-app.sh` and `open app/build/Lemna.app`:
  - Type a sentence, then ⌥← a few times: the caret stays at 60 %, the whole text glides right under it, word by word;
    the words after the caret show at full strength and fade out toward the right edge (gone at 95 %).
  - Fix a typo there: ← to it, ⌫ the wrong letter (the text before the caret glides back), type the right one (it
    comes out from under the caret; the text after it stays put).
  - → back to the end (or ⌘→ to the paragraph's end, ⌘← to its start): the text slides back; typing goes on as before.
  - ⌥⌫ takes the word before the caret (and the spaces after it); ⌦ the letter after the caret, ⌥⌦ the next word:
    the text after the caret closes up at once, without a glide.
  - Return in the middle: a muted ` ¶ ` appears at the caret and the rest of the paragraph follows it. ⌫ right after
    the ` ¶ ` (or ← past it, which lands before it, then ⌦) joins the paragraphs again.
  - Hold ←: the text runs right and never trails more than about a word behind; Reduce Motion: every step jumps.
  - Clicks: letters click as before; every ⌫, ⌥⌫, ⌦, ⌥⌦ that deletes clicks the backspace sound; ⌫ at the very start
    and ⌦ at the very end are silent; arrows are silent.
  - Dead keys and the accent menu mid-text: ← into a word, ´ then e, or hold e and pick é: it lands at the caret.
  - Restore: edit in the middle, ⌘Q, relaunch: the text is back with the caret at its end. A session left unfinished
    by yesterday's build (format 1): the first launch of this build shows its text as before and moves it into a new
    journal file without a word; `sessions.noindex/` then holds one new `<uuid>.journal` (starting `FLOWJ2`), the old
    one gone.
- App, pass 9 (2026-10-28; Harper removed, DESIGN.md R1+R3 amended, Plan item 7 marked removed): `lib/FlowHarper`
  (with its 589 MB Rust build folder), `Lint.swift`, `Suggestions.swift` and their tests are gone; `Package.swift` and
  `make-app.sh` are back to two dependencies and no cargo step, so the build needs no Rust toolchain. The review is
  pass 6's again (one text column, R1's line with Undo / Redo, the footer, the buttons); R1's Undo or Redo during a
  hand-off's grace still stops the grace (kept from pass 7b). 61 app tests pass (74 before; 13 went with Harper: the
  suggestion list's 10, the 2 through the real library, the list's keys), the journal's 14 (the login-keychain test
  skipped as before). `make-app.sh` builds, signs and verifies; the executable is 0.89 MB (886,816 bytes, was
  10,410,848). `app/README.md` (Pass 9) says what changed. Its try list was the review's, which pass 10 removed.
- App, pass 10 (2026-10-28; the review and the session frame removed, the user: "I do not want the first window
  after you pressed cmd+enter the first time, this is really not necessary. Also I don't like the time-box or intent
  modes, it's not really necessary."; DESIGN.md O1+O2+O3, R1+R3, W2, E2 amended, M1 removed, Plan items 3 and 5
  marked, Open 8 dropped): `Review.swift`, `FlowCore/Frame.swift` (time box, tone, log), the Time box… and Intent…
  sheets, `ReviewKey`, the grown box, the grace and its Undo, the duration and the word count are gone. ⌘⏎ (Done)
  applies R1 silently and pastes at once, or copies with the note at the box's bottom edge; Copy ⌘⇧⏎ and Save… ⌘S
  hand off R1's text too; every hand-off finishes the session at once (key destroyed, journal deleted). The Sound
  toggle and Discard… stay. 49 app tests pass (61 before: 9 went with the removed code, the time box's 2, the tone's,
  the log's 2, the review's keys, the grown box, the pasted grace and the word count; the state machine's 8 became 5
  for writing → handing off → cleared); `lib/LemnaJournal` is untouched. `make-app.sh` builds, signs with Flow Dev
  and verifies; the executable is 0.78 MB (779,680 bytes, was 890,448). Not tried: the builder showed no window.
  `app/README.md` (Pass 10) says what each part does. The menu-bar item's menu now: Show Lemna ⌃⌥Space, Open Window
  ⌃⌘F, Done ⌘⏎, Copy ⌘⇧⏎, Save… ⌘S, Discard…, Sound ⌘K, Quit Lemna ⌘Q. Try, after `app/make-app.sh` and
  `open app/build/Lemna.app`:
  - Paste at once: summon from TextEdit, type `teh boats sat low.  a idea`, ⌘⏎: no review; the box and the dim go and
    `Teh boats sat low. A idea` lands at TextEdit's cursor (R1: capitals, the double space). Since pass 11 the
    clipboard keeps that text (it held what it held before about a quarter second later until then). Summon again:
    an empty line.
  - Copy notes, each with the box staying up, the line empty and the text on the clipboard:
    - Secure Input: focus a password field (Safari, or Terminal with Secure Keyboard Entry on), summon, write, ⌘⏎:
      `Secure input is on: copied instead` at the box's bottom edge, nothing typed into the field. If the box first
      went and came back with that line, Secure Input came on only once the field had the keys again.
    - No permission (remove Lemna under Privacy & Security › Accessibility): ⌘⏎ brings macOS's prompt and
      `Copied · allow Lemna under Privacy & Security › Accessibility to paste`.
    - No target: summon from TextEdit, click into TextEdit through the dim and quit it (⌘Q), click the box, write,
      ⌘⏎: `Copied · no app to paste into`.
    - The next key clears the note and is typed into the new line; Esc clears it and hides the box; so do the hotkey
      and a click outside. Summon again: no note.
  - Copy: write, ⌘⇧⏎: the box goes; paste anywhere: R1's text. Summon: an empty line.
  - Save: write, ⌘S: the save panel as a sheet on the box (Lemna comes forward), `lemna-YYYY-MM-DD-HHMM.md`; save: the
    box goes and Lemna hides; the file holds R1's text, paragraphs apart by a blank line. Cancel instead: the line
    takes keys again with the text as it was.
  - Discard: the menu-bar item's Discard… asks once; Discard clears the line, Cancel keeps it.
  - Window mode: ⌃⌘F, write, ⌘⏎: copied, `Copied · no app to paste into` at the window's bottom edge, an empty line;
    Esc clears the note. ⌘⇧⏎ or ⌘S in the window: the hand-off, then Lemna hides.
  - From the menu-bar item with the box hidden (each off while the line is empty): Done pastes into the app in front,
    Copy copies, Save… brings the box with the panel on it.
  - Restore after `pkill -9 -x Lemna` mid-word: silent, as before.
- App, pass 11 (2026-10-28; the picks `A0+A1+A2+A3 P1 C1 D1 U1 F0 G1 H1 I1 N1` from
  `docs/design-panel-flow-sounds-name.html`, the user, P1 and U1 taken as recommended where left blank; DESIGN.md K1
  amended, F0 and G1 H1 new, O1+O2+O3 and E2 amended for I1, W2's accessibility, Plan item 9, Open 1 closed, Open 3
  names Hypha; the rename itself is a separate pass, after a trademark search): three click packs beside the Keychron
  in `lib/LemnaClicks`, 12 cuts each from Freesound's previews: Typewriter (a manual machine, CC0, low-passed at 3.5 kHz,
  125,764 bytes), Soft (MacBook Air keys with a FUJITSU Enter and Delete, CC0, 103,868 bytes), Electric (CC BY 4.0, its
  credit line in the pack and in `THIRD_PARTY.md`, 209,600 bytes); `THIRD_PARTY.md` has every source, licence check,
  command and measure, and `tools/cut_click.py` gained `--gain`, `--lead`, `--fade`, `--max`. `ClickPlayer(packs:)`
  loads every pack at launch and `pack` picks one by index, so a switch never loads anything on the key path. Session
  › Sound (and the menu-bar item's Sound) is a submenu: Keychron, Typewriter, Soft, Electric, Off ⌘K (radio ticks);
  ⌘K turns the sound off and back on with the last pack; the pack is kept as `soundPack` beside `sound`. A paste
  leaves Lemna's text on the clipboard: no restore, no read of the clipboard. The box is opaque under Reduce
  Transparency; the muted grey is #8d95a0 (6.3:1) under Increase Contrast; both read at each show. 51 app tests pass
  (49 before: the restore rule's test went with it, 2 for the Sound choice, 1 for the contrast), FlowClicks 14 of 15
  (11 before; new: each new pack's loading and per-key mapping, the CC BY credit line, a pack's picker in a shared
  table, all four packs in one player): the audible engine test was left out (`--skip playReturnsInMicroseconds`), no
  sound was played. `make-app.sh` copies the four packs, signs with Flow Dev and verifies; the executable is 0.80 MB
  (798,160 bytes, was 779,680), `Contents/Resources` 624 KB. Not tried, and nothing was listened to: the packs' filters,
  spans and levels are by measurement. `app/README.md` (Pass 11) says what each part does. Try, after `app/make-app.sh`
  and `open app/build/Lemna.app`:
  - Each pack at speed: the menu-bar item's Sound ▸ Typewriter, then type a fast burst (about 12 keys/s) for half a
    minute: clicks stay apart and none jumps out; Space, Return (a carriage-return lever) and ⌫ (a lighter, lower
    strike) each sound their own. Too dull, or still too bright? (The low-pass is one command in `THIRD_PARTY.md`.)
    Then Soft (on the MacBook's own keyboard: does it double the real key into a flam?), Electric (Return is a 0.6 s
    motor return), Keychron.
  - The submenu: a tick on the pack that plays; another pack plays from the next key, with no pause in the typing;
    relaunch: the same pack, ticked.
  - ⌘K: silent, Off ticked and no pack; ⌘K again: back with the pack that played last, not the Keychron. Off from the
    submenu does the same; a pack chosen while off turns the sound on. The Bluetooth notice as before.
  - Paste leaves the text: summon from TextEdit, write, ⌘⏎: it lands; ⌘V in TextEdit: the same text again, not what
    was on the clipboard before. No paste alert from macOS.
  - Reduce Transparency (System Settings › Accessibility › Display) on, summon: the box is opaque (over a bright
    window nothing shows through its edge); off: 97 % again at the next summon.
  - Increase Contrast (the same pane) on, summon: the ` ¶ ` (Return) and a note at the bottom edge (⌘⏎ in the window:
    `Copied · no app to paste into`) are a lighter grey; off: the dim grey again at the next summon.
- App, pass 12 (2026-10-28; the mark and the icon, DESIGN.md L1; the user: "M3 because it looks better in the small
  preview in the menu bar. I like I1, but it should be more related to the M3 icon then."): the menu-bar mark is M3,
  the tapered line (`StatusMark`), drawn per scale (Q2 of `docs/design-panel-icon-round-2.html`, taken): at 2× as
  M3's SVG has it, 1.5 pt right of the caret's left edge and narrowing from there to a point on the line's middle; at
  1× the last 2 pt stay 1 pt tall against the top edge, one whole pixel row instead of a grey wisp. The app icon is I1
  from M3, three variants in the same panel (J1 plain, J2 the thin end fading, J3 larger; recommended J2); the user rejected
  J2 ("looks like a triangle on the left") and picked K1 of `docs/design-panel-icon-round-3.html`, round 1's I1 as it was. `app/make-icon.swift` (run with `swift`, Command Line Tools only) draws an icon SVG at
  the iconset's ten sizes and packs `build/AppIcon.icns`; `make-app.sh` runs it on K1 (its `icon=` line), copies the
  `.icns` into `Contents/Resources` and sets `CFBundleIconFile`. `assets/logo/icons.py` writes the three SVGs. 51 app
  tests pass (the mark's test rewritten for the taper: at 2× M3's point, the rows above and below the middle alike,
  at 1× the whole top row; it writes `app/renders/mark-M3-1x.png` and `-2x.png`, the 2× one pixel for pixel AppKit's
  rendering of `mark-M3.svg`). `make-app.sh` builds, signs with Flow Dev and verifies; `Contents/Resources` 1,020 KB (393 KB of it
  the icon). Not tried: the builder launched nothing. `app/README.md` (Pass 12) says what each part does. Try, after
  `app/make-app.sh` and `open app/build/Lemna.app`:
  - The menu-bar mark on the Mac's own (2×) display, in a light and a dark menu bar: the line with the caret bar, its
    left part narrowing to a point, as the M3 of the round 1 panel. On a 1× external display, if there is one: the
    left end a whole line, not a grey smudge (each screen's menu bar draws the mark at its own scale).
  - The icon: Finder › `app/build/Lemna.app` › Get Info (⌘I): the icon at the top left, K1; Finder's icon view at a
    large size (⌘J) for the fade at the line's point; list view for 16 pt. There is no Dock icon at runtime
    (LSUIElement), so these are the places it shows. If Finder still shows the generic app icon, the bundle's old
    icon is cached: `touch app/build/Lemna.app`, or move the bundle once.
  - System Settings › Privacy & Security › Accessibility: Lemna's row with the new icon (after the next paste's
    prompt, or at once if Lemna is already listed).
- App, pass 13 (2026-10-28; the name, DESIGN.md N and Plan item 10; the user picked Lemna after name rounds 1 and 2):
  Flow is Lemna wherever the app shows its name: the menu-bar item's description and its menu (Show Lemna, Quit Lemna),
  About Lemna, the alerts, the paste note `Copied · allow Lemna under Privacy & Security › Accessibility to paste`, the
  save panel's `lemna-YYYY-MM-DD-HHMM.md`, the system log's lines. The bundle is `app/build/Lemna.app` (`CFBundleName`
  and `CFBundleExecutable` `Lemna`, `CFBundleIdentifier` `dev.lemna.app`), the keychain service `dev.lemna.app.session`,
  the folder `~/Library/Application Support/Lemna/sessions.noindex/`; the window's frame name, the queues' labels and
  the hotkey's Carbon signature (`'Lmna'`; the chord stays ⌃⌥Space) follow. The modules and folders: `Lemna`,
  `LemnaCore`, `LemnaCoreTests`, `lib/LemnaJournal`, `lib/LemnaClicks` and their tests. `make-cert.sh` makes "Lemna
  Dev"; `make-app.sh` signs with "Lemna Dev", else "Flow Dev" (so builds keep their signature until `make-cert.sh` runs
  again), else ad-hoc. Unchanged: the journal's format magic (`FLOWJ2`, `FLOWJ1`: a format, not a name; changing it
  would need a migration of its own), the pasteboard markers, the UserDefaults keys (`sound`, `soundPack`, `SaveFolder`:
  none carries the name). The journal migration (E2, P0): at each open (launch, and after each hand-off) `Journal.adopt`
  moves every journal in Flow's folder that has text in it and no lock on it into Lemna's folder, its key from
  `org.flow.app.session` into `dev.lemna.app.session` (stored first, then the file moved, then the old key destroyed; a
  crash anywhere leaves what the next open takes up). A session with nothing typed stays behind with its key, so it
  brings no keychain question; if the question is denied, nothing moves, the not-kept alert says why and the next launch
  asks again. Chosen over refusing to start with an alert naming the old folder (the text would stay out of reach
  without the old build), and without a condition "only while Lemna's folder is empty", which would strand a session
  typed into a still-running Flow after Lemna's first launch. Tests: the app's 51 as before; LemnaJournal 16 (14 before;
  new: a typed session comes along, after a store that would not answer; an empty one and one in use stay; the
  login-keychain test skipped as before); LemnaClicks 14 of 15 (`--skip playReturnsInMicroseconds`). `make-app.sh`
  builds and signs with Flow Dev (`codesign -dvv`: `Authority=Flow Dev`, `Identifier=dev.lemna.app`) and verifies; the
  executable is 0.80 MB (803,504 bytes, was 798,160), with no `/Users/` path in it; `app/build/Flow.app` is gone. The
  try lists above now name Lemna; the build reports keep "Flow Dev", which signed those builds. Not tried: nothing was
  launched. Try, after quitting Flow (it still ran from the old bundle at the rename: its menu-bar item › Quit Flow) and
  `open app/build/Lemna.app`:
  - The menu-bar item: its menu says Show Lemna and Quit Lemna. ⌃⌥Space summons the box as before; while Flow still runs
    it keeps the chord, and Lemna logs `Lemna: the hotkey could not be registered`.
  - Accessibility: the first ⌘⏎ brings macOS's prompt again, for the new bundle id: allow Lemna under Privacy & Security
    › Accessibility. Flow's old row there can go (select it, −).
  - Keychain: Keychain Access may keep `org.flow.app.session` items (the empty session Flow left at the rename):
    harmless, they open nothing Lemna reads; delete them if you like. Lemna's keys are under `dev.lemna.app.session`.
  - The migration: Flow's session was empty at the rename, so the first launch shows an empty line and asks nothing.
    Text typed into the running Flow before quitting it comes along: macOS asks whether Lemna may use the
    `org.flow.app.session` item (Allow), the text is on the line, and Lemna's folder holds that journal (the move itself
    is covered by LemnaJournal's tests). Flow's folder can then be deleted (left in it: at most an empty session, and
    `log.tsv`, the private log of M1).
  - Settings are kept per bundle id, so Lemna starts from the defaults: sound on with the Keychron (as Flow had it),
    Save… in the panel's default folder, the window centred.
  - After `app/make-cert.sh` (it makes "Lemna Dev") the next build signs with it: the Accessibility grant and the
    keychain item's access change once more (allow again; Always Allow). "Flow Dev" can then be deleted in Keychain
    Access, or kept as the fallback.
- App, pass 14 (2026-10-28; the effects, DESIGN.md F1 and Plan item 11, amending F0, W2, S1's curve and G1 H1; the user,
  after `docs/design-panel-lemna-effects.html`: "I like this, Go ahead with your picks", `T1 P1 G1 D1 Q1 B1 K1 E1+E2
  S1`): Tokyo Night's colours in the box and the window (#1a1b26, text #c0caf5, muted #7f88b2, caret #7aa2f7, line
  #3b4261; under Increase Contrast the muted grey #a9b1d6); the box opaque always, with a still 1 pt accent border
  instead of the hairline; the dim the box's background at 0.5 instead of black at 0.35; the box opening in 250 ms from
  95 % with a fade and closing in a 160 ms fade, the dim with it; the glide on easeOutQuint (the same 140 ms); the
  newest glyph popping in (120 ms, from 0 and 95 %); a sheen across the box at a hand-off; the ` ¶ ` fading in on
  Return; opt-in, off at first, the border warming with the keys and a sheen along it on Space; Session › Effects ▸
  (and the menu-bar item's) with Pop, Border warms, Glyph pop-in, Word sheen, Hand-off sheen, Paragraph fade and Off.
  Reduce Motion stops and greys Pop, Glyph pop-in and the sheens; the paragraph fade and the border's warmth stay. The
  close takes the box off screen at once and fades its last look in a window that takes no keys and no clicks, so
  nothing waits: Esc gives the keys back at once and a paste's ⌘V goes out at 120 ms as before. Tests: the app's 57
  (51 before; new: the Effects defaults, Off, Reduce Motion, the round trip through a dictionary, the entrance on the
  curve, the newest glyph's fade and scale in pixels; changed: the curve and the glide for easeOutQuint, the colours'
  contrast, the renders in the new colours with `pop-in-8ms.png`, `glide-8ms.png`, `paragraph-fade-25ms.png`,
  `paragraph-25ms.png`). The band's draw, measured beside the old loop (release, the box's band at 2×, best of five
  2,000 frames): 41.0–41.6 µs per frame before, 40.9–41.4 µs during a pop-in, 42.5 µs during the ` ¶ `'s fade.
  LemnaJournal 16 (the login-keychain test skipped), LemnaClicks 14 of 15 (`--skip playReturnsInMicroseconds`), both
  untouched. `make-app.sh` builds, signs with "Lemna Dev" (made since pass 13; `codesign -dvv`: `Authority=Lemna
  Dev`, `Identifier=dev.lemna.app`) and verifies; the executable is 0.90 MB (896,288 bytes, was 803,504), with no
  `/Users/` path in it. The first signing with the new key waited about nine minutes on macOS's keychain question
  (codesign asking to use the key "Lemna Dev") until it was answered; the rebuild after it signed without asking. The
  new signature (Lemna Dev, not Flow Dev) asks for the Accessibility grant and the keychain item's access once more.
  `app/README.md` (Pass 14) says what each part does. Not tried: nothing was launched. Try, after `app/make-app.sh` and
  `open app/build/Lemna.app`:
  - Open and close: summon from a light app (TextEdit) and a dark one: the box grows from a little smaller and fades in
    over a quarter second, the dim with it; type at once: the first letters land and show while it opens. Esc: it
    fades out over a sixth of a second. Does the open feel quick or slow? Does Esc feel laggy with the fade (the panel's
    risk line: Omarchy makes keyboard dismissals jump)? If it does, Effects ▸ Pop off makes both instant; say so, and
    Esc alone can jump. Type straight after Esc: the letters go to the app behind, none into Lemna. Summon again at
    once after Esc: the fading box is gone and the new one opens. Watch the box's shadow at the open's end: if it
    snaps in or out of place, that is the shadow taken again at full size.
  - The colours: the box #1a1b26 with the accent border, the text #c0caf5, the ` ¶ ` #7f88b2; the dim over a light and a
    dark app (the box's background at half strength; over a white page it should be calmer than before; over a dark
    terminal, nearly nothing). The window (⌃⌘F) in the same colours, without the border. The app icon is unchanged.
  - The glide: type at speed; the new letter comes out from under the caret faster at first (90 % in about 50 ms) and
    settles. Too jumpy? (One line in `Curve` takes the cubic back.)
  - Glyph pop-in at 12 keys/s: a fast burst for half a minute: each new letter fades in as it comes out from under the
    caret; does it read as softer, as lag, or not at all? Effects ▸ Glyph pop-in off for the difference.
  - Paragraph fade: Return: the ` ¶ ` fades in over about a tenth of a second.
  - Hand-off sheen vs paste timing: summon from TextEdit, write, ⌘⏎: a band of light crosses the box left to right as
    it fades, and the text lands in TextEdit at the same moment as before, not after the sheen. Also ⌘⇧⏎ (copy) and ⌘S
    (after the save panel's Save). ⌘⏎ in a password field (Secure Input): the box stays with its note and the sheen
    crosses it in place.
  - Each toggle in Session › Effects ▸ (the menu-bar item's): unticking one stops it from the next key or summon,
    relaunch keeps the ticks; Off: no pop, no pop-in, no sheen, no fade, the border still accent; Off again (or an item
    chosen while Off): back with the ticks.
  - Border warms (tick it): type: the border has the accent; stop: half a second later it cools to a dark grey-blue
    over 1.5 s; the next key brings the accent back in 150 ms. It should never dip between keys while typing on.
  - Word sheen (tick it): each Space sends a light along the border, top and bottom. Visible? Distracting?
  - Reduce Motion (System Settings › Accessibility › Display › Reduce motion): the box comes and goes at once, no
    pop-in, no sheens; in Effects ▸ Pop, Glyph pop-in, Word sheen and Hand-off sheen are grey and unticked; Paragraph
    fade and Border warms keep their ticks and still play; the glide jumps as before.
  - Increase Contrast (the same pane): the ` ¶ ` and a bottom-edge note a lighter grey (#a9b1d6) at the next summon.
- App, pass 14b (2026-10-28; DESIGN.md F1 amended, W2, G1 H1, Plan item 11): the user tried pass 14 (the
  Accessibility grant fixed, Reduce Motion off, every Effects item ticked): "Where are the new animations, I can barely
  see anything." and "I liked the color better before." Every magnitude is now in one table, `Effects.Tuning` in
  LemnaCore, with pass 14's values beside each as "subtle", and raised: Pop opens in 300 ms from 87 % (was 250 ms from
  95 %) and closes in 200 ms (was 160); the glyph pop-in grows from 70 % (was 95 %) and rises 3 pt from below the
  baseline (new) over 160 ms (was 120), still on easeOutQuint; the paragraph fade 200 ms (was 120); the hand-off sheen
  peak 0.35 (was 0.14) over 350 ms (was 300), the fade waiting until 150 ms so both end together; the word sheen peak
  0.7 (was 0.35); Border warms cools over 1.0 s after the 0.5 s quiet (was 1.5 s), the accent at full while typing,
  the warm-up 150 ms. The dim stays the box's background at 0.5. The colours are T2 again, as before pass 14:
  background #0e1013, text #d8dce3, muted #5c646f (#8d95a0 under Increase Contrast), caret and accent border #7aa7f0,
  the cooled border (B2) #262b32, the hairline the box had before; the box stays opaque (Q1). T1's contrast gain is
  lost: the muted grey is 3.2:1 again, below the HIG's 4.5:1 unless Increase Contrast is on. Tests: the app's 58 (57
  before; new: the tuning table; changed: the entrance for 70 %, 3 pt and 160 ms, the newest glyph's scale and rise in
  pixels, the colours' contrast and the renders' background and caret pixels back to T2). The band's draw beside the
  old loop (release, the box's band at 2×, best of five 2,000 frames, three runs): 41.5–41.8 µs per frame for the old
  loop, 41.5–42.2 at rest, 41.7–42.1 during a pop-in, 43.3–43.5 during the ` ¶ `'s fade, under the 45 µs asked.
  LemnaJournal and LemnaClicks untouched. `make-app.sh` builds, signs with "Lemna Dev" (`Authority=Lemna Dev`, no
  keychain question this time) and verifies; the executable is 0.91 MB (907,200 bytes, was 896,288), with no `/Users/`
  path in it. Not tried: nothing was launched. Try, after `app/make-app.sh` and `open app/build/Lemna.app`, with every
  Effects item ticked and Reduce Motion off:
  - Open: summon over a light app and a dark one: the box should visibly grow from about seven eighths of its size and
    fade in over about a third of a second, the dim with it. Type at once: the letters land while it opens. Too much
    now? `Effects.Tuning.open` and `openScale` are the knobs (pass 14 had 0.250 and 0.95).
  - Close: Esc: a fade over a fifth of a second; does Esc feel laggy now? Type straight after it: the letters go to the
    app behind. Pop unticked makes both instant.
  - Glyph pop-in at speed (about 12 keys/s for half a minute): each new letter comes out from under the caret small,
    low and faint and settles into place within about 60 ms. Visible without staring? Reads as softness or as lag?
    Does the line look jittery at speed? (`popInScale`, `popInRise`, `popIn`.)
  - Paragraph fade: Return: the ` ¶ ` fades in over a fifth of a second.
  - Hand-off sheen: summon from TextEdit, write, ⌘⏎: a clear band of light crosses the box left to right as it fades
    (a third of a second), and the text lands in TextEdit at the same moment as before, not after the sheen. Also ⌘⇧⏎
    and ⌘S (after the save panel's Save).
  - Word sheen: each Space sends a bright light along the border, top and bottom. Visible now? Too much at a word a
    second?
  - Border warms: type: the border bright blue; stop: half a second later it fades over a second to the dark hairline;
    the next key brings the blue back in 150 ms. It must not dip between keys while typing on.
  - The colours: the box and the window as before pass 14 (#0e1013, the light grey text, the blue caret), with the blue
    border; the dim over a light and a dark app.
  - Reduce Motion on: the box comes and goes at once, no pop-in, no sheens, those four items grey; the paragraph fade
    and Border warms still play. Increase Contrast on: the ` ¶ ` and a bottom-edge note lighter (#8d95a0).
- App, pass 15 (2026-10-28; the ambience, DESIGN.md A1 amending F0, Plan item 12; the user: "something like the
  omarchy-screensaver like ambient animations when typing. Some different modes that just make it look a bit cooler",
  then `M1+M2+M3+M4+M5+M6+M7 D0 R1 S1 C1 I1` of `docs/design-panel-lemna-ambience.html`): seven modes that play on the
  dim around the box while you type, each gone 4 s after the last key (its last second fading), never on the line:
  Drift (the line's own glyphs leave the box's left edge and drift off), Rain, Rings, Beams, Grid, Fireworks, Swarm.
  Session › Ambience ▸ (and the menu-bar item's) beside Sound and Effects: the seven, then Off, radio ticks, Off at
  first, kept as `ambience`; Reduce Motion greys the modes and plays none. Drift, Rings, Grid, Fireworks and Swarm play
  on the box's screen, Rain and Return's beam on every screen; nothing in window mode (⌃⌘F), which has no dim. Built as
  R1: a clear `CAMetalLayer` over each screen's shade, its own `CAMetalDisplayLink` at 60 Hz on one scene thread,
  paused and shrunk to one clear pixel when nothing plays; CPU particles in LemnaCore (`Ambience.Scene`, at most 2,000
  sprites), one Metal pipeline of instanced quads with a glyph atlas of the line's font, the shader compiled from
  source at runtime, once, at the box's show. The line's display link and band are untouched; the key handler hands
  the key on after its frame as a value (a lock and an append). Every magnitude is in `Ambience.Tuning` (the panel's
  I1 values; Drift's departure at the line's speed and Rain's 0.6 trail falloff added after the renders showed Drift
  bunching at the edge). Tests: the app's 76 (58 before, 18 new: the choice's default, round trip and Reduce Motion,
  the tuning, the sprite layout, the stage, the typing rate, the run's 4 s and its close, the glyph that leaves the
  box's edge, each mode's coupling, the cap in every mode, the shader compiled and one frame drawn offscreen, and
  `app/renders/ambience-<mode>.png`: each mode after 10 s of typing over a dimmed dark app with the box, drawn by the
  Metal pipeline); LemnaJournal 16 (the login-keychain test skipped), LemnaClicks 14 (`--skip
  playReturnsInMicroseconds`), both untouched. Measured (release, this Mac, 2×): a scene's step 1.6–24 µs a frame at the
  cap (Drift 24, Rings 17, Beams 10, Rain 9), encode, copy and commit 11 µs, the GPU 0.39 ms a frame for 2,000 glyphs
  over the screen; the shader's compile 53–361 ms uncached, 1–2 ms from the system's cache. The key's latency with a
  scene playing (the panel's budget: p50/p90 no worse than 42/60 ms) was not measured: nothing was launched.
  `make-app.sh` builds, signs with "Lemna Dev" (`Authority=Lemna Dev`) and verifies; the executable is 1.20 MB
  (1,202,384 bytes, was 907,200), with no `/Users/` path in it. `app/README.md` (Pass 15) says what each part does.
  Not tried: nothing was launched. Try, after `app/make-app.sh` and `open app/build/Lemna.app`, with Reduce Motion off:
  - The renders first, for the look: `app/renders/ambience-drift.png` and the six others.
  - Each mode at speed: the menu-bar item's Ambience ▸ Drift, summon over a dark app, type a long sentence at your
    pace (about 6 keys/s) for half a minute, then the same with Rain, Rings, Beams, Grid, Fireworks (Return now and
    then) and Swarm. Plainly visible without staring? Too much? Each is one row of `Ambience.Tuning`. Drift needs about
    32 characters on the line before the first glyph reaches the box's left edge.
  - Idle: stop typing: nothing new comes, the last second fades and by 4 s the dim is plain; Esc while it plays: the
    scene fades with the dim.
  - Over a light app (a white page in Safari or TextEdit) and a dark one (a terminal): over the light one the scenes
    nearly vanish (the panel's C1 risk); say whether that matters.
  - CPU: Activity Monitor (CPU tab, Lemna) while typing steadily with Rain: it should stay low (a few per cent); idle
    after 4 s: back to nothing. With a second screen, Rain falls there too.
  - Latency: does the line feel as quick as with Ambience ▸ Off? Type a burst at 12 keys/s with Rain or Rings, then Off.
  - The first scene after a launch: it starts with the first key (the shader compiles at the summon, off the main
    thread); if the very first keys show nothing for a moment, say so.
  - The menu: one tick at a time, Off last; another mode while typing takes over at the next key; relaunch keeps it.
    Window mode (⌃⌘F): no ambience. Reduce Motion on: the seven are grey, Off ticked, nothing plays; off again: the
    pick plays at the next summon.
- Next: the user quits Flow and tries pass 15, pass 14b (its list replaces pass 14's), pass 13, then pass 12, pass 11
  and pass 10, and what of v1, pass 6, pass 7b's click outside and pass 8 is still untried; then DESIGN.md's Open
  items.

## Build and run

- Spikes: `spikes/run-bench.sh` (two visible windows; under AeroSpace click the AppKit window once).
- App: `app/make-app.sh` builds in release with SwiftPM and assembles `app/build/Lemna.app`, signed with "Lemna Dev"
  (else "Flow Dev", else ad-hoc); the test command (with the Command Line Tools' `-F` flags) is in `app/README.md`. No
  Rust toolchain needed (since pass 9).

## Rules carried over

- No personal or site details in the repo (names, home paths, hosts); placeholders only.
- Commits: no Co-Authored-By trailers, no "Generated with" lines.
