# Handoff

`DESIGN.md` holds the decisions and the plan. This file says what is done and what is next.

## State (2026-10-27)

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
- Next: the user tries v1; then DESIGN.md's Later (R2 Harper, v1.5) and Open items.

## Build and run

- Spikes: `spikes/run-bench.sh` (two visible windows; under AeroSpace click the AppKit window once).
- App: `app/make-app.sh` builds in release with SwiftPM and assembles `app/build/Flow.app`, ad-hoc signed; the test
  command (with the Command Line Tools' `-F` flags) is in `app/README.md`.

## Rules carried over

- No personal or site details in the repo (names, home paths, hosts); placeholders only.
- Commits: no Co-Authored-By trailers, no "Generated with" lines.
