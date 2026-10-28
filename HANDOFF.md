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
  (`app/README.md` says what each part does), not yet tried by the user. The sheet was not rendered; its layout:
  - A sheet at the top of the window, dark `#14171b`, about 600 pt wide (72 characters of the 15 pt system font are
    ≈ 505 pt, plus margins; narrower in a narrow window), the window's height less 60 pt, at most 720, at least 240.
  - Top, filling the height: the text, read-only, selectable, scrollable, 15 pt system font in `#d9dde3`, with R1
    applied (paragraphs apart by a blank line).
  - Footer, 12 pt grey, under the text's left edge, one line each: `R1 · 5 fixes: 2 capitals, 1 double space,
    1 trailing space, 1 i → I ·` with a link-coloured Undo (then Redo; or `R1 · no fixes`); `12 min · 834 words`;
    after a hand-off `Copied ·` or `Saved flow-2026-10-27-2130.md ·` with Undo (10 s), or a failure in its place
    (`Not copied.`, `Not saved: …`, `Not finished: …`); `Not kept on disk: …` when the journal could not open.
  - Bottom row: Discard… alone at the left; Back, Save…, Copy at the right. Copy is a plain button now (⌘⏎; plain
    Return does nothing, milestone 5), not the blue default.
  - With an intent set (milestone 5): one muted line (13 pt, `#5c646f`) above the text.
- Try, after `app/make-app.sh` (the first launch makes a key in the login keychain; after each rebuild macOS may ask
  once whether Flow may use it, as the ad-hoc signature changed: Allow):
  - Done: type two sentences in lower case with a double space, ⌘⏎ (or Session › Done). The sheet shows them fixed;
    the R1 line counts the fixes; its Undo shows the raw text, Redo the fixed again.
  - Back: Esc or Back closes the sheet; type on, the line goes on from where it was; Done again shows all of it.
  - Copy + Undo: ⌘⏎ or Copy (plain Return does nothing), then paste somewhere: the shown text. The footer says
    `Copied · Undo (10 s)`; Undo within 10 s keeps the sheet and the session. Copy again and wait 10 s: the sheet
    closes, the surface is empty, a new session runs. A clipboard manager, if one runs, should not record the copy
    (Concealed/Transient markers).
  - Save: Save… (⌘S) offers `flow-YYYY-MM-DD-HHMM.md`; save, open the file (Markdown, a blank line between
    paragraphs); 10 s later the session ends. The next Save… opens in the same folder.
  - Discard: Discard… (in the sheet, or Session › Discard… while writing) asks once; Cancel keeps everything, Discard
    clears the surface for a new session.
  - Restore: type, ⌘Q, relaunch: the text is back without a dialog, the line ending where it was. The close button
    hides the window; the Dock icon shows it again with the text.
  - Crash: type steadily and run `pkill -9 -x Flow` from a terminal mid-word; relaunch: everything but the last
    ≤ 50 ms is there.
  - The folder: `~/Library/Application Support/Flow/sessions.noindex/` holds one `<uuid>.journal` per session; after
    a Done's grace or a Discard that file is gone and the new session's takes its place. `tmutil isexcluded` on the
    folder says excluded.
- App, the clicks (K1) and milestone 5 (W1 summoning, M1 session frame; Plan items 4 and 5): built, 44 tests pass
  (36 before, 8 new), `make-app.sh` assembles, signs and verifies the bundle with the click pack inside. v1 is
  complete as planned; none of it tried by the user yet. Try, after `app/make-app.sh`:
  - Clicks: type; each letter, space, Return and deleting backspace clicks, before the line moves. A backspace that
    does nothing (after a space, at a paragraph's start) is silent; so is typing while the review is up.
  - Sound: Session › Sound (⌘K) unticks and silences; relaunch: still off. ⌘K again: on.
  - Bluetooth notice: with Bluetooth headphones as the output (at launch, or switch to them while Flow runs):
    `Bluetooth output: clicks arrive late · ⌘K mutes`, small and grey, centred near the bottom edge, fading after 5 s;
    once per switch, not again for the same output. With the sound off: no notice, until ⌘K turns it on.
  - Hotkey ⌃⌥Space from another app: Flow's window comes to the front, key, ready to type. Again: Flow hides and the
    other app is back. Also after the close button, after ⌘M, and with the review sheet up.
  - Menu-bar item: a small line with a caret bar, light or dark with the menu bar. Its menu: Show Flow (⌃⌥Space),
    Done ⌘⏎ (from another app: Flow comes forward with the review), Sound with its check mark, Quit Flow.
  - Time box: Session › Time box…, pick 10 minutes, Set: a 1 pt line appears along the very bottom edge, grey on
    darker grey, filling from the left. After 10 minutes (the shortest choice), one soft tone, the line full; typing
    goes on. Set Off: the line goes. Set the same box again while it runs: nothing restarts.
  - Intent: Session › Intent…, type a line (it stops at 120 characters), Set. Nothing on the surface. Done: the line
    heads the review in grey. After the session ends (grace or Discard) it is gone, as is the time box.
  - ⌘⏎ in the review: Done (⌘⏎), then ⌘⏎ again copies (`Copied · Undo (10 s)`). Plain Return does nothing; Esc is
    Back. Holding ⌘⏎ a little long at Done does not copy.
  - Log: after a Copy's or Save's 10 s grace (not after Discard), Session › Show Log selects
    `~/Library/Application Support/Flow/log.tsv` in Finder; its last line holds four fields separated by tabs, like
    `2026-10-27 21:30 12 834` (start date, start time, whole minutes, words); `ls -l` shows `-rw-------`.
- Known for these (details in `app/README.md` Known gaps): `NSApp.activate()` may not bring Flow forward from a hotkey
  under macOS 14's cooperative activation (untried; the deprecated call is the fallback); ⌃⌥Space is macOS's default
  "Select next source in Input menu" where that shortcut is on; the time box stands still while the Mac sleeps;
  intent and time box do not survive a quit (memory only, by design).
- App, pass 6 (W2 the box, O3 paste at Done; Plan item 6): built, 51 tests pass (44 before, 7 new: the box's frame
  and clamps, the review grown from the bottom edge, one container at a time, the paste's decision table, the restore
  rule, the pasted grace), `make-app.sh` assembles, signs and verifies the bundle, now with `LSUIElement`. Not tried:
  the builder showed no window. `app/README.md` (Pass 6) says what each part does. It changes some of v1's lists
  above: nothing shows at launch and there is no Dock icon or menu bar (the menu-bar item's menu holds Open Window,
  Done, Discard…, Time box…, Intent…, Sound, Show Log, Quit); Esc hides the box; ⌃⌘F is Open Window (full screen
  only from the window's green button); the window's close button returns to the box. Try, after `app/make-app.sh`
  and `open app/build/Flow.app`:
  - Summon from another app (TextEdit, say): ⌃⌥Space or the menu-bar item's Show Flow. A dark rounded box about 60 %
    of the screen wide, a line tall, centred in the lower third of the screen with the pointer; every screen dimmed
    around it, the menu bar and Dock not. The app behind stays active (its name stays in the menu bar).
  - Type: the line glides as in the window; dead keys (´ then e), ⌥U then o, the accent menu on a held e, clicks.
  - Esc: box and dim gone at once, the app behind has the keys. Summon again: the text is still there.
  - Hotkey while the box is up: it goes. Click into another app through the dim, then the hotkey: the box takes the
    keys back.
  - Done in place: ⌘⏎. The box grows upward, its bottom edge where it was, to about 60 % of the screen's height, with
    the review (intent, text, footer, Discard… / Back, Save…, Copy, Paste). Esc or Back: back to the line.
  - Paste: ⌘⏎ again (or Paste). The first time, macOS asks for Accessibility and the footer says
    `Copied · allow Flow under Privacy & Security › Accessibility to paste` (the text is on the clipboard). Allow
    Flow under System Settings › Privacy & Security › Accessibility, then Done, ⌘⏎ again: the box goes and the text
    lands where the cursor was in TextEdit; then in Mail, then in a terminal. Copy something first: about a quarter
    second after the paste the clipboard holds that again. After each rebuild the ad-hoc signature changes and macOS
    may keep the old entry: if paste copies again, remove Flow from the Accessibility list (−) and allow it anew.
  - How Undo works after a paste: the box is hidden, so the 10 s grace runs in the background. Summon within 10 s:
    the review with `Pasted · Undo (10 s)`; Undo keeps the session and the text in Flow (the paste in the other app
    stays). Summon after 10 s: an empty line, a new session; the log has its line.
  - Hold ⌘⏎ a little long at the paste: the box waits for Return to come up, so no repeated ⌘⏎ reaches the app
    (which would send a message in many apps).
  - Secure Input: focus a password field (Safari, or Terminal with Secure Keyboard Entry on), summon, write, Done,
    ⌘⏎: `Secure input is on: copied instead` in the footer, nothing typed into the field. If the box first went and
    came back with that line, Secure Input came on only once the field had the keys again (the second check).
  - No target: summon from TextEdit, click into TextEdit through the dim and quit it (⌘Q), click the box, Done, ⌘⏎:
    `Copied · no app to paste into`.
  - Window mode: ⌃⌘F in the box (or Open Window in the menu-bar item): the box goes, Flow comes forward with v1's
    window and the same text, the line at 60 % of the window. ⌃⌘F again, or the close button: back to the box. Done
    in the window: v1's sheet, ⌘⏎ copies (no Paste there). In full screen (green button), ⌃⌘F leaves full screen
    first, then the box.
  - Over a full-screen app (Safari in full screen): the box and the dim show over it.
  - AeroSpace: it leaves the box and the dim alone (they float); whether it still tiles the window now that Flow has
    no Dock icon is open.
  - Time box…, Intent…, Discard… from the menu-bar item with the box hidden: the box comes, with the question as a
    sheet on it.
- App, pass 7b (a click outside hides the box; the pass also brought Harper's review, R2, Plan item 7, which pass 9
  removed): built, signed and verified; its one test that stays is the click-outside guard's table. Not tried: the
  builder showed no window. `app/README.md` (Pass 7b) says what it does. Try, after `app/make-app.sh` and
  `open app/build/Flow.app`:
  - Click outside: with the box up (writing or the review), click into another app or on the dim: box and dim go at
    once, that app has the keys; summon again: the box is back as it was (the review too). Not while a question or the
    save panel is up on the box, nor within a Copy's or Save's 10 s grace. Typing with the accent menu (hold e) or an
    input method should not hide it: watch for that.
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
  10,410,848). Not tried: the builder showed no window. `app/README.md` (Pass 9) says what changed. Try, after
  `app/make-app.sh` and `open app/build/Flow.app`:
  - Summon the box, type `teh boats sat low, a idea the the`, then Done (⌘⏎): the review shows R1's text
    (`Teh boats sat low, a idea the the`) in one column centred in the box, nothing beside or under it; the footer's
    first line `R1 · 1 fix: 1 capital · Undo`, then the duration and words; Discard… / Back, Save…, Copy, Paste.
  - Keys in the review: ⌘⏎ pastes, Esc is Back, plain Return does nothing; ↑ and ↓ scroll a long text.
  - Copy, then Undo on the R1 line within the 10 s: the `Copied · Undo` line goes and the session stays (the grace
    stopped); Copy again: the raw text is on the clipboard.
  - Window mode: ⌃⌘F, Done: the sheet is as wide as the text column and its margins (about 600 pt), not 950.
- Next: the user tries v1, pass 6, pass 7b's click outside, pass 8 and pass 9; then DESIGN.md's Open items.

## Build and run

- Spikes: `spikes/run-bench.sh` (two visible windows; under AeroSpace click the AppKit window once).
- App: `app/make-app.sh` builds in release with SwiftPM and assembles `app/build/Flow.app`, ad-hoc signed; the test
  command (with the Command Line Tools' `-F` flags) is in `app/README.md`. No Rust toolchain needed (since pass 9).

## Rules carried over

- No personal or site details in the repo (names, home paths, hosts); placeholders only.
- Commits: no Co-Authored-By trailers, no "Generated with" lines.
