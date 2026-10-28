# Handoff

`DESIGN.md` holds the decisions and the plan. This file says what is done and what is next.

## State (2026-10-28)

- Research, panel, report: done (`docs/`, `reports/`, `research_notes/`).
- Spike GPUI vs AppKit: done, results in `DESIGN.md`; the user chose T2 (Swift + AppKit).
- App, milestone 1 (surface): built in `app/` from `spikes/appkit-line`, tests pass (`app/README.md`), not yet tried
  by the user. Try `open app/build/Flow.app` after `app/make-app.sh`:
  - Type a few sentences: the line glides left, the new letter comes out from under the caret, the old words fade.
  - Dead keys on the German layout: ´ then e gives é; ⌥U then o gives ö. Holding e should offer the accent menu at
    the caret.
  - Return: a muted ` ¶ ` on the line; twice leaves a blank line (` ¶  ¶ `).
  - Backspace: deletes within the current word only; after a space, or at a paragraph's start, it does nothing.
  - Resize the window (the caret stays at 60 %), full screen (green button or ⌃⌘F), AeroSpace: tiled, keeps focus.
  - Esc, arrows and clicks do nothing.
- Libraries: `lib/FlowJournal` (milestone 2, E2) and `lib/FlowClicks` (milestone 4, K1), committed with their tests.
- App, milestones 2 and 3 (the journal in the app; Done → review → copy / save / discard; R1): built, 36 tests pass
  (`app/README.md` says what each part does). The review sheet, R1's undo and the 10 s grace went in pass 10 (below),
  and with them this list's items on the sheet, Done, Back, Copy, Save and Discard. Try, after `app/make-app.sh` (the
  first launch makes a key in the login keychain; after each rebuild macOS may ask once whether Flow may use it, as the
  ad-hoc signature changed: Allow):
  - Restore: type, ⌘Q, relaunch: the text is back without a dialog, the line ending where it was. The close button
    hides the window; the Dock icon shows it again with the text.
  - Crash: type steadily and run `pkill -9 -x Flow` from a terminal mid-word; relaunch: everything but the last
    ≤ 50 ms is there.
  - The folder: `~/Library/Application Support/Flow/sessions.noindex/` holds one `<uuid>.journal` per session; after
    a paste, Copy, Save or Discard that file is gone and the new session's takes its place. `tmutil isexcluded` on the
    folder says excluded.
- App, the clicks (K1) and milestone 5 (W1 summoning, M1 session frame; Plan items 4 and 5): built, 44 tests pass
  (36 before, 8 new), `make-app.sh` assembles, signs and verifies the bundle with the click pack inside. v1 is
  complete as planned. The session frame (M1) went in pass 10, and with it this list's items on the time box, the
  intent, the review's ⌘⏎ and the log. Try, after `app/make-app.sh`:
  - Clicks: type; each letter, space, Return and deleting backspace clicks, before the line moves. A backspace that
    does nothing (after a space, at a paragraph's start) is silent.
  - Sound: Session › Sound (⌘K) unticks and silences; relaunch: still off. ⌘K again: on.
  - Bluetooth notice: with Bluetooth headphones as the output (at launch, or switch to them while Flow runs):
    `Bluetooth output: clicks arrive late · ⌘K mutes`, small and grey, centred near the bottom edge, fading after 5 s;
    once per switch, not again for the same output. With the sound off: no notice, until ⌘K turns it on.
  - Hotkey ⌃⌥Space from another app: Flow's window comes to the front, key, ready to type. Again: Flow hides and the
    other app is back. Also after the close button and after ⌘M.
  - Menu-bar item: a small line with a caret bar, light or dark with the menu bar. Its menu: pass 10 lists it.
- Known for these (details in `app/README.md` Known gaps): `NSApp.activate()` may not bring Flow forward from a hotkey
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
  copy notes. Try, after `app/make-app.sh` and `open app/build/Flow.app`:
  - Summon from another app (TextEdit, say): ⌃⌥Space or the menu-bar item's Show Flow. A dark rounded box about 60 %
    of the screen wide, a line tall, centred in the lower third of the screen with the pointer; every screen dimmed
    around it, the menu bar and Dock not. The app behind stays active (its name stays in the menu bar).
  - Type: the line glides as in the window; dead keys (´ then e), ⌥U then o, the accent menu on a held e, clicks.
  - Esc: box and dim gone at once, the app behind has the keys. Summon again: the text is still there.
  - Hotkey while the box is up: it goes. Click into another app through the dim, then the hotkey: the box takes the
    keys back.
  - Hold ⌘⏎ a little long at the paste: the box waits for Return to come up, so no repeated ⌘⏎ reaches the app
    (which would send a message in many apps).
  - Window mode: ⌃⌘F in the box (or Open Window in the menu-bar item): the box goes, Flow comes forward with v1's
    window and the same text, the line at 60 % of the window. ⌃⌘F again, or the close button: back to the box. In
    full screen (green button), ⌃⌘F leaves full screen first, then the box.
  - Over a full-screen app (Safari in full screen): the box and the dim show over it.
  - AeroSpace: it leaves the box and the dim alone (they float); whether it still tiles the window now that Flow has
    no Dock icon is open.
  - Discard… from the menu-bar item with the box hidden: the box comes, with the question as a sheet on it.
- App, pass 7b (a click outside hides the box; the pass also brought Harper's review, R2, Plan item 7, which pass 9
  removed): built, signed and verified; its one test that stays is the click-outside guard's table. Not tried: the
  builder showed no window. `app/README.md` (Pass 7b) says what it does. Try, after `app/make-app.sh` and
  `open app/build/Flow.app`:
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
  does; the journal's format 2 is in `lib/FlowJournal/README.md`. It changes v1's list above: ⌫ deletes across spaces
  and paragraph ends, and the arrows move the caret. Try, after `app/make-app.sh` and `open app/build/Flow.app`:
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
  applies R1 silently and pastes at once, or copies with the note at the box's bottom edge; Copy ⌘⇧C and Save… ⌘S
  hand off R1's text too; every hand-off finishes the session at once (key destroyed, journal deleted). The Sound
  toggle and Discard… stay. 49 app tests pass (61 before: 9 went with the removed code, the time box's 2, the tone's,
  the log's 2, the review's keys, the grown box, the pasted grace and the word count; the state machine's 8 became 5
  for writing → handing off → cleared); `lib/FlowJournal` is untouched. `make-app.sh` builds, signs with Flow Dev
  and verifies; the executable is 0.78 MB (779,680 bytes, was 890,448). Not tried: the builder showed no window.
  `app/README.md` (Pass 10) says what each part does. The menu-bar item's menu now: Show Flow ⌃⌥Space, Open Window
  ⌃⌘F, Done ⌘⏎, Copy ⌘⇧C, Save… ⌘S, Discard…, Sound ⌘K, Quit Flow ⌘Q. Try, after `app/make-app.sh` and
  `open app/build/Flow.app`:
  - Paste at once: summon from TextEdit, type `teh boats sat low.  a idea`, ⌘⏎: no review; the box and the dim go and
    `Teh boats sat low. A idea` lands at TextEdit's cursor (R1: capitals, the double space). The clipboard holds what
    it held before about a quarter second later. Summon again: an empty line.
  - Copy notes, each with the box staying up, the line empty and the text on the clipboard:
    - Secure Input: focus a password field (Safari, or Terminal with Secure Keyboard Entry on), summon, write, ⌘⏎:
      `Secure input is on: copied instead` at the box's bottom edge, nothing typed into the field. If the box first
      went and came back with that line, Secure Input came on only once the field had the keys again.
    - No permission (remove Flow under Privacy & Security › Accessibility): ⌘⏎ brings macOS's prompt and
      `Copied · allow Flow under Privacy & Security › Accessibility to paste`.
    - No target: summon from TextEdit, click into TextEdit through the dim and quit it (⌘Q), click the box, write,
      ⌘⏎: `Copied · no app to paste into`.
    - The next key clears the note and is typed into the new line; Esc clears it and hides the box; so do the hotkey
      and a click outside. Summon again: no note.
  - Copy: write, ⌘⇧C: the box goes; paste anywhere: R1's text. Summon: an empty line.
  - Save: write, ⌘S: the save panel as a sheet on the box (Flow comes forward), `flow-YYYY-MM-DD-HHMM.md`; save: the
    box goes and Flow hides; the file holds R1's text, paragraphs apart by a blank line. Cancel instead: the line
    takes keys again with the text as it was.
  - Discard: the menu-bar item's Discard… asks once; Discard clears the line, Cancel keeps it.
  - Window mode: ⌃⌘F, write, ⌘⏎: copied, `Copied · no app to paste into` at the window's bottom edge, an empty line;
    Esc clears the note. ⌘⇧C or ⌘S in the window: the hand-off, then Flow hides.
  - From the menu-bar item with the box hidden (each off while the line is empty): Done pastes into the app in front,
    Copy copies, Save… brings the box with the panel on it.
  - Restore after `pkill -9 -x Flow` mid-word: silent, as before.
- Next: the user tries pass 10, and what of v1, pass 6, pass 7b's click outside and pass 8 is still untried; then
  DESIGN.md's Open items.

## Build and run

- Spikes: `spikes/run-bench.sh` (two visible windows; under AeroSpace click the AppKit window once).
- App: `app/make-app.sh` builds in release with SwiftPM and assembles `app/build/Flow.app`, ad-hoc signed; the test
  command (with the Command Line Tools' `-F` flags) is in `app/README.md`. No Rust toolchain needed (since pass 9).

## Rules carried over

- No personal or site details in the repo (names, home paths, hosts); placeholders only.
- Commits: no Co-Authored-By trailers, no "Generated with" lines.
