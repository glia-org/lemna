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
  - Esc, arrows and clicks do nothing; ⌘Q and closing the window quit, and the text is gone (no journal yet).
- Next: milestone 2, the journal (DESIGN.md E2).

## Build and run

- Spikes: `spikes/run-bench.sh` (two visible windows; under AeroSpace click the AppKit window once).
- App: `app/make-app.sh` builds in release with SwiftPM and assembles `app/build/Flow.app`, ad-hoc signed; the test
  command (with the Command Line Tools' `-F` flags) is in `app/README.md`.

## Rules carried over

- No personal or site details in the repo (names, home paths, hosts); placeholders only.
- Commits: no Co-Authored-By trailers, no "Generated with" lines.
